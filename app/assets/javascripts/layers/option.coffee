onLayers ->
  class @Option
    constructor: (data) ->
      @id = ko.observable(data?.id)
      @code = ko.observable(data?.code)
      @label = ko.observable(data?.label)
      @editing = ko.observable(false)
      @hasFocus = ko.observable(false)

    edit: => @editing(true)

    keyPress: (field, event) =>
      switch event.keyCode
        when 13 then @editing(false)
        else true

    toJSON: =>
      id: @id()
      code: @code()
      label: @label()

