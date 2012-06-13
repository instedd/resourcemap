#= require thresholds/value_type
#= require thresholds/operator

onThresholds ->
  class @Condition
    constructor: (data) ->
      @field = ko.observable window.model.findField data?.field
      @compareField = ko.observable window.model.findField data?.compare_field
      @op = ko.observable Operator.findByCode data?.op
      @value = ko.observable data?.value
      @valueType = ko.observable ValueType.findByCode data?.type ? 'value'
      @formattedValue = ko.computed =>
        switch @field()?.kind()
          when 'select_one', 'select_many'
            @field().findOptionById(@value())?.label()
          else "#{@valueType()?.format @value()}"
      @error = ko.computed => return "value is missing" unless @value()
      @valid = ko.computed => not @error()?

    toJSON: =>
      field: @field().esCode()
      op: @op().code()
      value: @value()
      type: @valueType().code()
      compare_field: @compareField()?.esCode()
