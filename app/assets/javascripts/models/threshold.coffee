#= require models/condition

$ ->
  module 'rm'

  rm.Threshold = class Threshold
    
    constructor: (data) ->
      @id = data?.id
      @collection_id = data.collection_id
      @priority = ko.observable data?.priority
      @color = ko.observable data?.color
      data.conditions ?= []
      @conditions = ko.observableArray $.map data.conditions, (condition) -> new rm.Condition condition

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
