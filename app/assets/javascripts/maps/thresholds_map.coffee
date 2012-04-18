$ ->
  module 'rm'

  rm.EventDispatcher.bind rm.SystemEvent.GLOBAL_MODELS, (event) ->
    rm.thresholdsViewModel = new rm.ThresholdsViewModel

  rm.EventDispatcher.bind rm.SystemEvent.INITIALIZE, (event) ->
    ko.applyBindings rm.thresholdsViewModel

    $.getJSON "/collections/#{rm.get 'collection_id'}/thresholds.json", (data) ->
      thresholds = $.map data, (threshold) -> new rm.Threshold threshold
      rm.thresholdsViewModel.thresholds thresholds

  rm.EventDispatcher.bind rm.ThresholdEvent.DESTROY, (event) ->
    $.post "/collections/#{rm.get 'collection_id'}/thresholds/#{event.threshold.id()}.json", { _method: 'delete' }, ->
      rm.thresholdsViewModel.thresholds.remove event.threshold
