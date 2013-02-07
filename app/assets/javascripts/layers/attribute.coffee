onLayers ->
  class @Attribute
    constructor: (data) ->
      @key = ko.observable(data?.code)
      @value = ko.observable(data?.value)
      @editing = ko.observable(false)
      @hasFocus = ko.observable(false)

    edit: => @editing(true)

    keyPress: (field, event) =>
      switch event.keyCode
        when 13 then @editing(false)
        else true

    toJSON: =>
      key: @key()
      value: @value()

    @find: (list, attribute) ->
      _.find list, (a) -> (a.key() == attribute.key()) and (a.value() == attribute.value())

