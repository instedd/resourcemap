#= require collections/collection_decorator

onCollections ->

  # A collection that groups the items by a hierarchy field
  class @CollectionHierarchy extends CollectionDecorator
    constructor: (collection, field) ->
      super(collection)

      @field = field
      @hierarchyItemsMap = {}
      @hierarchyItems = $.map field.hierarchy, (x) => new HierarchyItem(@, field, x)

    isSearch: => false

    sitesUrl: =>
      "/collections/#{@id()}/search.json?#{$.param @queryParams()}"

    queryParams: =>
      @setQueryParams {}

    setQueryParams: (q) =>
      q.hierarchy_code = @field.esCode
      q

    addSite: (site, isNew = false) =>
      # We also add the site to the original collection
      # or to the hierarchy item where it belongs, if it's a new site
      if isNew
        @collection.addSite site

        if site.properties()[@field.esCode]
          item = @hierarchyItemsMap[site.properties()[@field.esCode]]
          item.addSite site if item && item.sitesPage > 1
        else
          super(site)
      else
        super(site)

    # The next two methods are invoked when a site's hierarchy field changes
    # value: we need to move it from the old node to the new node.
    performHierarchyChanges: (site, changes) =>
      for change in changes
        if change.field.esCode == @field.esCode
          @performHierarchyChange(site, change)

    performHierarchyChange: (site, change) =>
      if change.oldValue?
        item = @hierarchyItemsMap[change.oldValue]
        item.removeSite(site) if item
      else
        @removeSite(site)

      item = @hierarchyItemsMap[change.newValue]
      item.addSite(site) if item && item.sitesPage > 1
