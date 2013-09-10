onLayers ->

  class @HierarchyItem

    constructor: (data, parent, level = 0) ->
      @id = ko.observable(data?.id)
      @idPrevious = ko.observable()
      @idError =  ko.observable(false)

      @name = ko.observable(data?.name)
      @namePrevious = ko.observable()
      @nameError =  ko.observable(false)


      @errorMessage = ko.observable()

      @level = ko.observable(level)
      @parent = parent
      @active = ko.observable(false)
      @editing = ko.observable(false)

      @newItemName = ko.observable()
      @newItemIdOverwritten = ko.observable(false)

      @newItemId = ko.observable()

      @newItemIdUI = ko.computed
        read: =>
          name = @newItemName()
          if @newItemIdOverwritten()
            @newItemId()
          else
            name?.replace(/\ /g, "_")
        write: (value) =>
          @newItemIdOverwritten(true)
          @newItemId(value)

      @newItemNameError = ko.observable(false)
      @newItemIdError = ko.observable(false)
      @newItemErrorMessage = ko.observable()

      @addingItem = ko.observable(false)
      @expanded = ko.observable(false)
      @hierarchyItems = if data.sub?
                          ko.observableArray($.map(data.sub, (x) => new HierarchyItem(x, @, level + 1)))
                        else
                          ko.observableArray()

    toggleExpand: =>
      @expanded(!@expanded())
      true

    setActive: =>
      @active(true)
      true

    removeActive: =>
      @active(false)
      true

    edit: =>
      @idPrevious(@id())
      @namePrevious(@name())
      @editing(true)

    calculateErrorMessage: =>
      @errorMessage("")
      @idError(false)
      @nameError(true)
      if !@name()
        @nameError(true)
        @errorMessage("Item name is required.")
      if !@id()
        @idError(true)
        @errorMessage(@errorMessage() + " Item id is required.")
      if window.model.currentHierarchyUnderEdition().findById(@id()).length > 1
        @idError(true)
        @errorMessage(@errorMessage() + " Item id already exists.")

    calculateErrorMessageForNewItem: =>
      @newItemErrorMessage("")
      @newItemIdError(false)
      @newItemNameError(false)
      if !@newItemName()
        @newItemNameError(true)
        @newItemErrorMessage("Item name is required.")
      if !@newItemIdUI()
        @newItemIdError(true)
        @newItemErrorMessage(@newItemErrorMessage() + " Item id is required.")
      if window.model.currentHierarchyUnderEdition().findById(@newItemIdUI()).length > 1
        @newItemIdError(true)
        @newItemErrorMessage(@newItemErrorMessage() + " Item id already exists.")

    saveChanges: =>
      @calculateErrorMessage()

      if !@errorMessage()
        @idPrevious(null)
        @namePrevious(null)
        @editing(false)
        true

    discardChanges: =>
      @errorMessage("")
      @idError(false)
      @nameError(false)
      @id(@idPrevious())
      @name(@namePrevious())
      @idPrevious(null)
      @namePrevious(null)
      @editing(false)

    toJSON: =>
      {id: @id(), name: @name(), sub: $.map(@hierarchyItems(), (x) -> x.toJSON())}

    openAddItem: =>
      @expanded(true)
      @addingItem(true)

    addItem: =>
      @calculateErrorMessageForNewItem()

      if !@newItemErrorMessage()
        newItem = new HierarchyItem({name: @newItemName(), id: @newItemIdUI()}, @, @level() + 1)
        @hierarchyItems.unshift(newItem)
        @closeAddingItem()

    closeAddingItem: =>
      @newItemErrorMessage("")
      @newItemIdError(false)
      @newItemNameError(false)
      @newItemIdUI(null)
      @newItemName(null)
      @newItemIdOverwritten(false)
      @addingItem(false)

    deleteItem: =>
      confirmation = confirm("Do you want to delete this item and its children?")
      @parent.hierarchyItems.remove(this) if confirmation

    collapseAll: =>
      @expanded(false)
      for hierarchyItem in @hierarchyItems()
        hierarchyItem.collapseAll()

    findById: (idToFind) =>
      elements = []
      elements.push(this) if (idToFind == @id() )
      elements.push(this) if (idToFind == @newItemIdUI() )
      for hierarchyItem in @hierarchyItems()
        for foundElement in hierarchyItem.findById(idToFind)
          elements.push(foundElement)
      elements
