onLayers ->
  class @Hierarchy
    constructor: (field) ->
      @field = ko.observable field
      initHierarchyData = field.impl().hierarchy() || []
      @hierarchyItems = ko.observableArray $.map(initHierarchyData, (x) => new HierarchyItem(x, @))
      @addingItem = ko.observable(false)

      @newItemName = ko.observable()
      @newItemId = ko.observable()
      @newItemNameError = ko.observable(false)
      @newItemIdError = ko.observable(false)
      @newItemErrorMessage = ko.observable()

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
      @calculateErrorMessageForNewItem()

      if !@newItemErrorMessage()
        newItem = new HierarchyItem({name: @newItemName(), id: @newItemId()}, @, 0)
        @hierarchyItems.push(newItem)
        @closeAddingItem()

    closeAddingItem: =>
      @newItemErrorMessage("")
      @newItemIdError(false)
      @newItemNameError(false)
      @newItemName(null)
      @newItemId(null)
      @addingItem(false)

    calculateErrorMessageForNewItem: =>
      @newItemErrorMessage("")
      @newItemIdError(false)
      @newItemNameError(false)
      if !@newItemName()
        @newItemNameError(true)
        @newItemErrorMessage("Item name is required.")
      if !@newItemId()
        @newItemIdError(true)
        @newItemErrorMessage(@newItemErrorMessage() + " Item id is required.")
      if window.model.currentHierarchyUnderEdition().findById(@newItemId()).length > 1
        @newItemIdError(true)
        @newItemErrorMessage(@newItemErrorMessage() + " Item id already exists.")


    findById: (idToFind) =>
      elements = []
      elements.push(this) if (idToFind == @newItemId())
      for hierarchyItem in @hierarchyItems()
        for foundElement in hierarchyItem.findById(idToFind)
          elements.push(foundElement)
      elements






