onLayers ->

  class @HierarchyItem

    constructor: (data, parent, level = 0) ->
      @id = ko.observable(data?.id)
      @name = ko.observable(data?.name)
      @level = ko.observable(level)
      @parent = parent
      @active = ko.observable(false)
      @newItemName = ko.observable()
      @newItemId = ko.observable()
      @addingItem = ko.observable(false)
      @expanded = ko.observable(false)
      @hierarchyItems = if data.sub?
                          ko.observableArray($.map(data.sub, (x) => new HierarchyItem(x, @, level + 1)))
                        else
                          ko.observableArray()

    toggleExpand: =>
      @expanded(!@expanded())
      false

    toggleActive: =>
      @active(!@active())
      false

    toJSON: =>
      {id: @id(), name: @name(), sub: $.map(@hierarchyItems(), (x) -> x.toJSON())}

    openAddItem: =>
      @expanded(true)
      @addingItem(true)

    addItem: =>
      newItem = new HierarchyItem({name: @newItemName(), id: @newItemId()}, @, @level() + 1)
      @hierarchyItems.unshift(newItem)
      @closeAddingItem()

    closeAddingItem: =>
      @newItemName(null)
      @newItemId(null)
      @addingItem(false)

    deleteItem: =>
      @parent.hierarchyItems.remove(this)

    collapseAll: =>
      @expanded(false)
      for hierarchyItem in @hierarchyItems()
        hierarchyItem.collapseAll()
