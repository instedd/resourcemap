$ ->
  module 'rm'

  rm.EventDispatcher.bind rm.SystemEvent.GLOBAL_MODELS, (event) ->
    rm.thresholdsViewModel = new rm.ThresholdsViewModel rm.get 'collection_id'

  rm.EventDispatcher.bind rm.SystemEvent.INITIALIZE, (event) ->
    ko.applyBindings rm.thresholdsViewModel

    $.getJSON "/collections/#{rm.thresholdsViewModel.collectionId}/thresholds.json", (data) ->
      thresholds = $.map data, (threshold) -> new rm.Threshold threshold
      rm.thresholdsViewModel.thresholds thresholds

  rm.EventDispatcher.bind rm.ThresholdEvent.DESTROY, (event) ->
    $.post "/collections/#{rm.thresholdsViewModel.collectionId}/thresholds/#{event.threshold.id()}.json", { _method: 'delete' }, ->
      rm.thresholdsViewModel.thresholds.remove event.threshold
