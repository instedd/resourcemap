onCollections ->

  # Used when selecting a hierarchy field value
  class @FieldHierarchyItem
    constructor: (field, data, parent = null, level = 0) ->
      field.fieldHierarchyItemsMap[data.id] = data.name

      @field = field
      @parent = parent

      @id = data.id
      @name = data.name
      @level = level
      @expanded = ko.observable(false)
      @selected = ko.computed => @field.value() == @id
      @fieldHierarchyItems = if data.sub?
                          $.map data.sub, (x) => new FieldHierarchyItem(@field, x, @, level + 1)
                        else
                          []
      @selected.subscribe (newValue) =>
        @toggleParentsExpand() if newValue
      @hierarchyIds = ko.observable([@id])
      $.map @fieldHierarchyItems, (item) => @loadItemToHierarchyIds(item)

    loadItemToHierarchyIds: (item) =>
      @hierarchyIds().push(item.id)
      $.map item.fieldHierarchyItems, (item) => @loadItemToHierarchyIds(item)

    toggleExpand: =>
      @expanded(!@expanded())

    toggleParentsExpand: =>
      @expanded(true) if @field.value() != @id
      @parent.toggleParentsExpand() if @parent


    select: => @field.value(@id)
