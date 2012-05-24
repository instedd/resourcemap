onThresholds ->
  class @ValueType
    @VALUE = new ValueType('value', 'a value of', (value) -> value)
    @PERCENTAGE = new ValueType('percentage', 'a percentage of', (value) -> "#{value}%")
    @ALL = [@VALUE, @PERCENTAGE]

    constructor: (code, label, format) ->
      @code = ko.observable code
      @label = ko.observable label
      @format = format

    @findByCode: (code) ->
      @[code?.toUpperCase()]
