$ ->
  module 'rm'

  rm.EventDispatcher.bind rm.SystemEvent.GLOBAL_MODELS, (event) ->
    rm.thresholdsViewModel = new rm.ThresholdsViewModel

  rm.EventDispatcher.bind rm.SystemEvent.INITIALIZE, (event) ->
    ko.applyBindings rm.thresholdsViewModel

    $.getJSON "/collections/#{rm.get 'collection_id'}/thresholds.json", (data) ->
      thresholds = $.map data, (threshold) -> new rm.Threshold threshold
      console.log thresholds 
      rm.thresholdsViewModel.thresholds thresholds
