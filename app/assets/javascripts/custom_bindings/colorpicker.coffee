ko.bindingHandlers.colorPicker =
  init: (element, valueAccessor) ->
    value = valueAccessor()
    $(element).val ko.utils.unwrapObservable value
    $(element).colorPicker()

    $(element).change -> value @value

  update: (element, valueAccessor) ->
    $(element).val ko.utils.unwrapObservable valueAccessor()
