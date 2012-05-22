#= require models/threshold

$ ->
  module 'rm'

  rm.ThresholdsViewModel = class ThresholdsViewModel

    @Messages =
      DELETE_THRESHOLD: 'Are you sure to delete threshold?'

    @States =
      LISTING     : 'listing',
      ADDING_NEW  : 'adding_new',
      EDITING     : 'editing'

    constructor: (@collectionId) ->
      @fields = ko.observableArray()
      @thresholds = ko.observableArray()
      @state = ko.observable ThresholdsViewModel.States.LISTING
      @currentThreshold = ko.observable()
      @isReady = ko.observable()

    deleteThreshold: (threshold) =>
      threshold.destroy() if confirm ThresholdsViewModel.Messages.DELETE_THRESHOLD

    moveThresholdUp: (threshold) =>
      index = @thresholds.indexOf threshold
      @_swapPriority threshold, @thresholds()[index - 1] if index > 0

    moveThresholdDown: (threshold) =>
      index = @thresholds.indexOf threshold
      @_swapPriority threshold, @thresholds()[index + 1] if index < @thresholds().length - 1

    refresh: ->
      @thresholds.sort (x, y) -> x.priority() > y.priority() ? -1 : 1
      
    saveThreshold: () =>
      if @state() == ThresholdsViewModel.States.EDITING
        rm.thresholdsViewModel.currentThreshold().update() 
      else
        rm.thresholdsViewModel.currentThreshold().create()

    addCondition: () ->
      con = {
        field: "Beds"
        is: "gt"
        value: "10"
      }
      rm.thresholdsViewModel.currentThreshold().addCondition(con)

    saveThresholdSuccess: (threshold) ->
      @currentThreshold().id(threshold.id)
      @currentThreshold(null)
      @state ThresholdsViewModel.States.LISTING
    
    showAddThreshold: () ->
      @state ThresholdsViewModel.States.ADDING_NEW
      @_setCurrentThreshold(new rm.Threshold { collection_id: @collectionId })
      @thresholds.push @currentThreshold()

    cancelThreshold: =>
      @_setCurrentThreshold null
      @state ThresholdsViewModel.States.LISTING

    editThreshold: (threshold) =>
      @_setCurrentThreshold threshold
      @state ThresholdsViewModel.States.EDITING

    getField: (code) ->
      for field in @fields()
        return field if field.code() == code

    # _newThreshold: ->
    #   lastThresholdPriority = @thresholds()[@thresholds().length - 1]?.priority() ? 0
    #   new rm.Threshold
    #     collection_id: @collectionId
    #     priority: lastThresholdPriority + 1
    #     color: "#0000ff"
    #     conditions: [ ]

    # _getLastThreshold: ->
    #   @thresholds()[@thresholds().length - 1] if @thresholds().length > 0

    _setCurrentThreshold: (threshold)->
      @thresholds.remove @currentThreshold() if @currentThreshold()?.isNewRecord()
      @currentThreshold threshold
      
    _swapPriority: (x, y) ->
      priority = x.priority()
      x.setPriority y.priority()
      y.setPriority priority
      @refresh()
