onLayers ->

  class @HierarchyItem

    constructor: (data, parent, level = 0) ->
      @id = ko.observable(data?.id)
      @idPrevious = ko.observable()

      @name = ko.observable(data?.name)
      @namePrevious = ko.observable()

      @level = ko.observable(level)
      @parent = parent
      @active = ko.observable(false)
      @editing = ko.observable(false)
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
      true

    toggleActive: =>
      @active(!@active())
      true

    edit: =>
      @idPrevious(@id())
      @namePrevious(@name())
      @editing(true)

    saveChanges: =>
      @idPrevious(null)
      @namePrevious(null)
      @editing(false)
      true

    discardChanges: =>
      @id(@idPrevious())
      @name(@namePrevious())
      @idPrevious(null)
      @namePrevious(null)
      @editing(false)
      true

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
      confirmation = confirm("Do you want to delete this item and its children?")
      @parent.hierarchyItems.remove(this) if confirmation

    collapseAll: =>
      @expanded(false)
      for hierarchyItem in @hierarchyItems()
        hierarchyItem.collapseAll()
