$(-> if $('#collections-main').length > 0

  class window.Layer
    constructor: (data) ->
      @name = ko.observable data?.name
      @fields = ko.observableArray($.map(data.fields, (x) => new Field(x)))
      @expanded = ko.observable(true)

    toggleExpand: =>
      @expanded(!@expanded())

)
