$ ->
  module 'rm'

  rm.Threshold = class Threshold

    @ComparisonOperators =
      lt: 'less than'
      gt: 'greater than'
    
    constructor: (data) ->
      
      @id = ko.observable data?.id
      @collection_id = data.collection_id
      @priority = ko.observable data?.priority
      @priority.subscribe => rm.EventDispatcher.trigger rm.ThresholdEvent.CHANGE_PRIORITY, new rm.ThresholdEvent @

      @condition = ko.observable data?.condition
      @comparisonValue = ko.observable @condition().is
      @valueOrPercent = ko.observable data?.valueOrPercent
      @field = ko.observable @condition().field
      @color = ko.observable data?.color
      @valueOrPercenValue = ko.observable @condition().value
      @priority.subscribe => rm.EventDispatcher.trigger rm.ThresholdEvent.CHANGE_PRIORITY, new rm.ThresholdEvent @
      @borderTopStyle = ko.computed => "1px inset #{@color()}"
      @comparisonText = ko.observable Threshold.ComparisonOperators[@condition().is] 
      
      @comparisonValue.subscribe =>
        @comparisonText Threshold.ComparisonOperators[@comparisonValue()]
      
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

    setPriority: (priority) ->
      @priority priority
      rm.EventDispatcher.trigger rm.ThresholdEvent.SET_PRIORITY, new rm.ThresholdEvent @

    toJSON: ->
      json =
        priority: @priority(),
        color: @color(),
        condition:{
          field: @field()
          is: @comparisonValue()
          value: @condition().value
        }
