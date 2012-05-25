#= require thresholds/value_type

onThresholds ->
  class @Condition
    constructor: (data) ->
      @field = ko.observable window.model.findField(data?.field)
      @op = ko.observable Operator.findByCode data?.op
      @value = ko.observable data?.value
      @valueType = ko.observable ValueType.findByCode data?.type
      @formattedValue = ko.computed => @valueType()?.format(@value())
      @error = ko.computed => return "value is missing" unless @value()
      @valid = ko.computed => not @error()?

    toJSON: =>
      field: @field().esCode()
      op: @op().code()
      value: @value()
      type: @valueType().code()
