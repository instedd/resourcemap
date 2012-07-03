ko.bindingHandlers.autocomplete =
  init: (element, valueAccessor, allBindingsAccessor) ->
    value = valueAccessor()
    bindings = allBindingsAccessor()

    $(element).val ko.utils.unwrapObservable value
    $(element).autocomplete
      source: bindings.source
      select: -> value @value

  update: (element, valueAccessor) ->
    $(element).val ko.utils.unwrapObservable valueAccessor()
