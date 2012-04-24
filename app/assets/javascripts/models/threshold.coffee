$ ->
  module 'rm'

  rm.Threshold = class Threshold

    @ComparisonOperators =
      lt: 'less than'
      mt: 'more than'
    
    @ComparisonOperatorsReverse = 
      lt: 'is less than' 
      mt: 'is more than'

    constructor: (data) ->
      @id = ko.observable data?.id
      @collection_id = data.collection_id
      @priority = ko.observable data?.priority
      @priority.subscribe => rm.EventDispatcher.trigger rm.ThresholdEvent.CHANGE_PRIORITY, new rm.ThresholdEvent @

      @color = ko.observable data?.color
      @borderTopStyle = ko.computed => "1px inset #{@color()}"
      @condition = ko.observable data?.condition
      @field = ko.computed => @condition().field
      @comparison = ko.computed => Threshold.ComparisonOperators[@condition().is] 
      @comp = ko.observable => data?.comp
      @valueOforPercentOf = ko.observable data?.valueOforPercentOf
      @condition().is = ko.computed =>
        @comp().comparison_key
      @value = ko.computed =>
        if 'number' == typeof @condition().value
          @condition().value
        else
          percent = (@condition().value[0] * 100).toFixed 0
          "#{percent}% of #{@condition().value[1]}"

    destroy: ->
      event = new rm.ThresholdEvent @
      rm.EventDispatcher.trigger rm.ThresholdEvent.DESTROY, event

    create: ->
      event = new rm.ThresholdEvent @
      rm.EventDispatcher.trigger rm.ThresholdEvent.CREATE, event

    toJSON: ->
      json =
        priority: @priority(),
        color: @color(),
        condition: @condition()
