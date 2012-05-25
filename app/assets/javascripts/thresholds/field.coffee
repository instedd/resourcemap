#= require thresholds/operator
onThresholds ->
  class @Field
    constructor: (data) ->
      @esCode = ko.observable "#{data.id}"
      @name = ko.observable data.name
      @code = ko.observable data.code
      @kind = ko.observable data.kind
      @operators = ko.computed =>
        switch @kind()
          when 'text' then [Operator.EQ, Operator.CON]
          when 'numeric' then [Operator.EQ, Operator.LT, Operator.GT]
          else []
