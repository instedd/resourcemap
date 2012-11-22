#= require module
#= require collections/site
#= require collections/cluster
#= require collections/constants

#= require collections/collections_view_model
#= require collections/sites_view_model
#= require collections/export_links_view_model
#= require collections/map_view_model
#= require collections/refine_view_model
#= require collections/search_view_model
#= require collections/sort_view_model
#= require collections/url_rewrite_view_model
#= require collections/gateways_view_model
onCollections ->

  class @MainViewModel extends Module
    @include CollectionsViewModel
    @include SitesViewModel
    @include ExportLinksViewModel
    @include MapViewModel
    @include RefineViewModel
    @include SearchViewModel
    @include SortViewModel
    @include UrlRewriteViewModel
    @include GatewaysViewModel

    initialize: (collections) ->
      @callModuleConstructors(arguments)
      @groupBy = ko.observable(@defaultGroupBy)

      @filters.subscribe => @performSearchOrHierarchy()
      @groupBy.subscribe => @performSearchOrHierarchy()

      @shouldShowLocationMissingAlert = ko.computed =>
        !@filteringByProperty(FilterByLocationMissing) && @currentCollection()?.sitesWithoutLocation().length > 0
      @locationMissingAlertText = ko.computed =>
        n = @currentCollection()?.sitesWithoutLocation().length
        singular = n == 1
        "There #{if singular then "is one site" else "are #{n} sites"} with no location set"

      @showThemText = ko.computed =>
        if @currentCollection()?.sitesWithoutLocation().length == 1
          "Show it"
        else
          "Show them"

      @processingURL = true

      # We make sure all the methods in this model are correctly bound to "this".
      # Using Module and @include makes the methods in the included class not bound
      # to this, and they don't work when being invoked by knockout when interacting
      # with the view.
      @[k] = v.bind(@) for k, v of @ when v.bind? && !ko.isObservable(v)

    defaultGroupBy: {esCode: '', name: 'None'}

    showPopupWithMaxValueOfProperty: (field, event) =>
      # Create a popup that first says "Loading...", then loads the content via ajax.
      # The popup is removed when on mouse out.
      offset = $(event.target).offset()
      element = $("<div style=\"position:absolute;top:#{offset.top - 30}px;left:#{offset.left}px;padding:4px;background-color:black;color:white;border:1px solid grey\">Loading maximum value...</div>")
      $(document.body).append(element)
      mouseoutHandler = ->
        element.remove()
        $(event.target).unbind 'mouseout', mouseoutHandler
      event = $(event.target).bind 'mouseout', mouseoutHandler
      $.get "/collections/#{@currentCollection().id}/max_value_of_property.json", {property: field.esCode}, (data) =>
        element.text "Maximum #{field.name}: #{data}"

    refreshTimeago: -> $('.timeago').timeago()

    processURL: ->
      selectedSiteId = null
      selectedCollectionId = null
      editingSiteId = null
      editingCollectionId = null
      showTable = false
      groupBy = null

      if (value = $.url().param('collection') ? $.url().param('editing_collection')) and not @currentCollection()
        @enterCollection value
        return

      queryParams = $.url().param()
      for key of queryParams
        value = queryParams[key]
        switch key
          when 'lat', 'lng', 'z'
            continue
          when 'search'
            @search(value)
          when 'updated_since'
            switch value
              when 'last_hour' then @filterByLastHour()
              when 'last_day' then @filterByLastDay()
              when 'last_week' then @filterByLastWeek()
              when 'last_month' then @filterByLastMonth()
          when 'selected_site'
            selectedSiteId = parseInt(value)
          when 'selected_collection'
            selectedCollectionId = parseInt(value)
          when 'editing_site'
            editingSiteId = parseInt(value)
          when 'editing_collection', 'collection'
            editingCollectionId = parseInt(value)
          when '_table'
            showTable = true
          when 'hierarchy_code'
            groupBy = value
          when 'sort'
            @sort(value)
          when 'sort_direction'
            @sortDirection(value == 'asc')
          else
            continue if not @currentCollection()
            @expandedRefineProperty(key)

            if value.length >= 2 && value[0] in ['>', '<', '~'] && value[1] == '='
              @expandedRefinePropertyOperator(value.substring(0, 2))
              @expandedRefinePropertyValue(value.substring(2))
            else if value[0] in ['=', '>', '<']
              @expandedRefinePropertyOperator(value[0])
              @expandedRefinePropertyValue(value.substring(1))
            else
              @expandedRefinePropertyValue(value)
            @filterByProperty()

      @ignorePerformSearchOrHierarchy = false
      @performSearchOrHierarchy()

      @showTable() if showTable
      @selectSiteFromId(selectedSiteId, selectedCollectionId) if selectedSiteId
      @editSiteFromMarker(editingSiteId, editingCollectionId) if editingSiteId
      @groupBy(@currentCollection().findFieldByEsCode(groupBy)) if groupBy && @currentCollection()

      @processingURL = false
  
    isGatewayExist: =>
      _self = @ 
      $.get "/gateways.json", (data) ->
        _self.isExist(true) if data.length > 0
        $('#profile-main').show()
