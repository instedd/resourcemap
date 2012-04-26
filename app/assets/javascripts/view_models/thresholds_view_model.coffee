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
      @state = ko.observable ThresholdsViewModel.States.LISTING
      @currentThreshold = ko.observable()
      @fieldsOption = [
        "bed"
        "hospital"
        "car garage"
        "petro station"
      ]

      @comparisonsOption = [
        comparison_value: "is less than"
        comparison_key: "lt"
      ,
        comparison_value: "is more than"
        comparison_key: "mt"
      ]

      @ofOption = [
        "a value of"
        "a percent of"
      ]

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
      
    addThreshold: () ->
      rm.thresholdsViewModel.currentThreshold().create()

    showAddThreshold: () ->
      @state ThresholdsViewModel.States.ADDING_NEW
      defaultThreshold =
        collection_id: @collectionId
        valueOforPercentOf: @ofOption[0]
        priority: @thresholds().length + 1
        comp: @comparisonsOption[1]
        value: 10
        comparison: @comparisonsOption[0].comparison_key
        condition: {
          field: ko.observable(@fieldsOption[0])
          is: "lt"
          value: ko.observable(10)
        }
        color: "#FFFFFF"
      threshold = new rm.Threshold defaultThreshold
      @thresholds.push threshold
      @currentThreshold(threshold)

    cancelThreshold: =>
      @thresholds.remove @currentThreshold()
      @currentThreshold null
      @state ThresholdsViewModel.States.LISTING
      
    _swapPriority: (x, y) ->
      priority = x.priority()
      x.setPriority y.priority()
      y.setPriority priority
      @refresh()
