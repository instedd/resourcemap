onLayers ->
  class @Hierarchy
    constructor: (field) ->
      @field = ko.observable field
      initHierarchyData = field.impl().hierarchy() || []
      @hierarchyItems = ko.observableArray $.map(initHierarchyData, (x) => new HierarchyItem(x, @))
      @addingItem = ko.observable(false)
      @newItemName = ko.observable()
      @newItemId = ko.observable()

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

    openAddItem: =>
      @addingItem(true)

    addItem: =>
      newItem = new HierarchyItem({name: @newItemName(), id: @newItemId()}, @, 0)
      @hierarchyItems.push(newItem)
      @closeAddingItem()

    closeAddingItem: =>
      @newItemName(null)
      @newItemId(null)
      @addingItem(false)






