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
    @include CustomLogoViewModel

    constructor: (collections, @api = Resmap.Api) ->
      @initialize(collections, @api)

    initialize: (collections, api) ->
      @sitesCount = ko.observable(0)

      @sitesWithoutLocation = ko.observable(false)
      @newSiteProperties = {}

      @callModuleConstructors(arguments)
      @groupBy = ko.observable(@defaultGroupBy)

      @filters.subscribe => @performSearchOrHierarchy()
      @groupBy.subscribe => @performSearchOrHierarchy()

      @shouldShowLocationMissingAlert = ko.computed =>
        !@filteringByProperty(FilterByLocationMissing) && @sitesWithoutLocation()

      @processingURL = true

      @updateSitesInfo()
      @siteCountText = ko.computed =>
        if @currentCollection() && @currentCollection().siteSearchCount() != @sitesCount()
          if @currentCollection().siteSearchCount() == 1
            Jed.sprintf(window.__("Showing 1 site out of %d"),@sitesCount())
          else
            Jed.sprintf(window.__("Showing %d sites out of %d"),@currentCollection().siteSearchCount(),@sitesCount())
        else
          Jed.sprintf(window.__("Showing all %d sites"),@sitesCount())

      # We make sure all the methods in this model are correctly bound to "this".
      # Using Module and @include makes the methods in the included class not bound
      # to this, and they don't work when being invoked by knockout when interacting
      # with the view.
      @[k] = v.bind(@) for k, v of @ when v.bind? && !ko.isObservable(v)

    updateSitesInfo: =>
      if @currentCollection()
        @api.Collections.getSitesInfo(@currentCollection().id).then (data) =>
          @sitesCount data.total
          @sitesWithoutLocation data.no_location
          @newSiteProperties = data.new_site_properties
      else
        @sitesCount(0)
        @sitesWithoutLocation(false)
        @newSiteProperties = {}

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
      @api.Collections.getMaxValueOfProperty(@currentCollection().id, field.esCode).then (data) =>
        element.text "Maximum #{field.name}: #{data}"

    refreshTimeago: -> $('.timeago').timeago()

    isGatewayExist: =>
      @api.Gateways.all().then (data) =>
        @isExist(true) if data.length > 0
        $('#profile-main').show()

    refreshMapResize: =>
      map = window.model.map
      if map
        setTimeout (->
          center = map.getCenter()
          google.maps.event.trigger(map, 'resize')
          map.panTo(center)
          ), 300
