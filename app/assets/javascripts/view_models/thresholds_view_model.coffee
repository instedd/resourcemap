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

    deleteThreshold: (threshold) =>
      threshold.destroy() if confirm ThresholdsViewModel.Messages.DELETE_THRESHOLD

    increasePriority: (threshold) =>
      index = @thresholds.indexOf threshold
      @swapPriority threshold, @thresholds()[index - 1] if index > 0

    decreasePriority: (threshold) =>
      index = @thresholds.indexOf threshold
      @swapPriority threshold, @thresholds()[index + 1] if index < @thresholds().length - 1

    swapPriority: (x, y) ->
      priority = x.priority()
      x.priority y.priority()
      y.priority priority
      @refresh()

    refresh: ->
      @thresholds.sort (x, y) -> x.priority() > y.priority() ? -1 : 1
