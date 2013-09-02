onLayers ->
  class @HierarchyItem
    constructor: (data, level = 0) ->
      @id = ko.observable(data?.id)
      @name = ko.observable(data?.name)
      @level = ko.observable(level)
      @expanded = ko.observable(false)
      @hierarchyItems = if data.sub?
                          ko.observableArray($.map(data.sub, (x) -> new HierarchyItem(x, level + 1)))
                        else
                          ko.observableArray()

    toggleExpand: =>
      @expanded(!@expanded())
      false

    toJSON: =>
      {id: @id(), name: @name(), sub: $.map(@hierarchyItems(), (x) -> x.toJSON())}

    collapseAll: =>
      @expanded(false)
      for hierarchyItem in @hierarchyItems()
        hierarchyItem.collapseAll()


