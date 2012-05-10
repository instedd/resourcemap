$(-> if $('#collections-main').length > 0

  # Used when grouping by a hierarchy field
  class window.HierarchyItem extends Module
    @include SitesContainer

    constructor: (collection, field, data, level = 0) ->
      @constructorSitesContainer()

      @field = field

      collection.hierarchyItemsMap[data.id] = @

      @id = ko.observable(data.id)
      @name = ko.observable(data.name)
      @level = ko.observable(level)
      @selected = ko.observable(false)
      @hierarchyItems = if data.sub?
                          ko.observableArray($.map(data.sub, (x) => new HierarchyItem(collection, @field, x, level + 1)))
                        else
                          ko.observableArray()

    sitesUrl: =>
      "/collections/#{window.model.currentCollection().id()}/search.json?#{$.param @queryParams()}"

    queryParams: =>
      hierarchy_code: @field.code()
      hierarchy_value: @id()

    createSite: (site) => new Site(window.model.currentCollection().collection, site)

)
