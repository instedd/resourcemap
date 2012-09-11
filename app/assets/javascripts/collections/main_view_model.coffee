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
