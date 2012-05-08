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
      @thresholds = ko.observableArray()
      @fields = ko.observableArray() 
      @state = ko.observable ThresholdsViewModel.States.LISTING
      @currentThreshold = ko.observable()

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

    saveThresholdSuccess: () ->
      @currentThreshold(null)
      @state ThresholdsViewModel.States.LISTING
    
    showAddThreshold: () ->
      @state ThresholdsViewModel.States.ADDING_NEW
      defaultThreshold =
        collection_id: @collectionId
        valueOrPercent: "percent"
        priority:  @thresholds().length + 1
        color: "#0000ff"
        conditions: [
          field: "Beds"
          is: "gt"
          value: "10"
        ]
      threshold = new rm.Threshold defaultThreshold
      @thresholds.push threshold
      @_setCurrentThreshold(threshold)

    cancelThreshold: =>
      @_setCurrentThreshold null
      @state ThresholdsViewModel.States.LISTING

    editThreshold: (threshold) =>
      @_setCurrentThreshold threshold
      @state ThresholdsViewModel.States.EDITING

    _setCurrentThreshold: (threshold)->
      @thresholds.remove @currentThreshold() if @currentThreshold()?.isNewRecord()
      @currentThreshold threshold
      
    _swapPriority: (x, y) ->
      priority = x.priority()
      x.setPriority y.priority()
      y.setPriority priority
      @refresh()
