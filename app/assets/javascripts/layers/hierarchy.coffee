onLayers ->
  class @Hierarchy
    constructor: (field) ->
      @field = ko.observable field
      initHierarchyData = field.impl().hierarchy() || []
      @hierarchyItems = ko.observableArray $.map(initHierarchyData, (x) => new HierarchyItem(x, @))

    toJSON: =>
      $.map(@hierarchyItems(), (x) -> x.toJSON())

    collapseAll: =>
      for hierarchyItem in @hierarchyItems()
        hierarchyItem.collapseAll()

    saveHierarchy:  =>
      @field().impl().setHierarchy(@toJSON())
      @closeFancyBox()

    closeFancyBox: =>
      $.fancybox.close()



