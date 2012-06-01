ko.bindingHandlers.superblyTagField =
  init: (element, valueAccessor) ->
    value = valueAccessor()
    $(element).val ko.utils.unwrapObservable value    
    
    window.model.loadSites (sites) ->
      $(element).superblyTagField {preset: [], allowNewTags: false, tags: sites}
    
    $(element).change -> value @value

  update: (element, valueAccessor) ->
    $(element).val ko.utils.unwrapObservable valueAccessor()