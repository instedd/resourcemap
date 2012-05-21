#= require models/condition

$ ->
  module 'rm'

  rm.Threshold = class Threshold
    
    constructor: (data) ->
      # _self = this 
      @id = data?.id
      @collection_id = data.collection_id
      @priority = ko.observable data?.priority
      @color = ko.observable data?.color
      @conditions = ko.observableArray $.map data.conditions, (condition) -> new rm.Condition condition
      # @valueOrPercent = ko.observable data?.valueOrPercent
      # @priority.subscribe => rm.EventDispatcher.trigger rm.ThresholdEvent.CHANGE_PRIORITY, new rm.ThresholdEvent @
      # @borderTopStyle = ko.computed => "1px inset #{@color()}"
      # $.map data.conditions, (con) ->
      #    
      #   condition = {}
      #   condition.field = ko.observable con.field
      #   condition.comparisonText = ko.observable Threshold.ComparisonOperators[con.is]
      #   condition.is = ko.observable con.is 
      #   condition.comparisonValue = ko.observable con.value
      #   condition.valueOrPercent = ko.observable "value" 
      #   condition.comparisonValue.subscribe =>
      #     condition.comparisonText Threshold.ComparisonOperators[condition.comparisonValue]
      #   condition.value = ko.computed =>
      #     if 'number' == typeof con.value
      #       con.value
      #     else
      #       con.value 
      #       #percent = (con.value[0] * 100).toFixed 0
      #       #"#{percent}% of #{con.value[1]}"
      #   _self.conditions.push condition

    destroy: ->
      event = new rm.ThresholdEvent @
      rm.EventDispatcher.trigger rm.ThresholdEvent.DESTROY, event

    create: ->
      event = new rm.ThresholdEvent @
      rm.EventDispatcher.trigger rm.ThresholdEvent.CREATE, event

    update: ->
      event = new rm.ThresholdEvent @
      rm.EventDispatcher.trigger rm.ThresholdEvent.UPDATE, event

    setPriority: (priority) ->
      @priority priority
      rm.EventDispatcher.trigger rm.ThresholdEvent.SET_PRIORITY, new rm.ThresholdEvent @

    # addCondition:(con) ->
    #   condition = {}
    #   condition.field = ko.observable con.field
    #   condition.comparisonText = ko.observable Threshold.ComparisonOperators[con.is]
    #   condition.is = ko.observable con.is 
    #   condition.comparisonValue = ko.observable con.value
    #   condition.valueOrPercent = ko.observable "value" 
    #   condition.comparisonValue.subscribe =>
    #     condition.comparisonText Threshold.ComparisonOperators[condition.comparisonValue]
    #   condition.value = ko.computed =>
    #     if 'number' == typeof con.value
    #       con.value
    #     else
    #       con.value 
    #   @conditions.push (condition)

    isNewRecord: ->
      not @id?

    # toJSON: ->
    #   conditions = []
    #   $.map @conditions(), (con) ->
    #     condition = {}
    #     condition.field = con.field()
    #     condition.is = con.is()
    #     condition.value = con.value()
    #     conditions.push condition
    #   json =
    #     priority  : @priority(),
    #     color     : @color(),
    #     conditions : conditions

    isFirstCondition: (condition) ->
      0 == @conditions().indexOf condition

    isLastCondition: (condition) ->
      @conditions().length - 1 == @conditions().indexOf condition

    addNewCondition: =>
      @conditions.push new rm.Condition

    removeCondition: (condition) =>
      @conditions.remove condition
