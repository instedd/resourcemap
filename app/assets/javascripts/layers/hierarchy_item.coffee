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

