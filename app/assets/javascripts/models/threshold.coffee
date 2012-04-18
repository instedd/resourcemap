$ ->
  module 'rm'

  rm.Threshold = class Threshold

    @ComparisonOperators =
      lt: 'less than'
      mt: 'more than'
    constructor: (data) ->
      @id = ko.observable data?.id
      @priority = ko.observable data?.priority
      @color = ko.observable data?.color
      @borderTopStyle = ko.computed => "1px inset #{@color()}"
      @condition = ko.observable data?.condition
      @field = ko.computed => @condition().field
      @comparison = ko.computed => Threshold.ComparisonOperators[@condition().is]
      @value = ko.computed =>
        if 'number' == typeof @condition().value
          @condition().value
        else
          percent = (@condition().value[0] * 100).toFixed 0
          "#{percent}% of #{@condition().value[1]}"
