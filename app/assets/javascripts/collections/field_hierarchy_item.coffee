onCollections ->

  # Used when selecting a hierarchy field value
  class @FieldHierarchyItem
    constructor: (field, data, parent = null, level = 0) ->
      field.fieldHierarchyItemsMap[data.id] = data.name

      @field = field
      @parent = parent

      @id = ko.observable(data.id)
      @name = ko.observable(data.name)
      @level = ko.observable(level)
      @expanded = ko.observable(false)
      @selected = ko.computed => @field.value() == @id()
      @fieldHierarchyItems = if data.sub?
                          ko.observableArray($.map(data.sub, (x) => new FieldHierarchyItem(@field, x, @, level + 1)))
                        else
                          ko.observableArray()
      @selected.subscribe (newValue) =>
        @toggleParentsExpand() if newValue

    toggleExpand: =>
      @expanded(!@expanded())

    toggleParentsExpand: =>
      @expanded(true) if @field.value() != @id()
      @parent.toggleParentsExpand() if @parent

    select: => @field.value(@id())
