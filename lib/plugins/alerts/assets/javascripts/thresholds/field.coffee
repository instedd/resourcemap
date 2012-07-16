#= require thresholds/operator
#= require thresholds/option
onThresholds ->
  class @Field
    constructor: (data) ->
      @esCode = ko.observable "#{data.id}"
      @name = ko.observable data.name
      @code = ko.observable data.code
      @kind = ko.observable data.kind
      @options = ko.observableArray $.map data.config?.options ? [], (option) -> new Option option
      @operators = ko.computed =>
        switch @kind()
          when 'text' then [Operator.EQ, Operator.CON]
          when 'numeric' then [Operator.EQ, Operator.LT, Operator.GT]
          when 'select_one' then [Operator.EQ]
          when 'select_many' then [Operator.EQ]
          else []

    findOptionById: (optionId) ->
      return option for option in @options() when option.id() == optionId
