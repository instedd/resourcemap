ko.bindingHandlers.autocomplete =
  init: (element, valueAccessor, allBindingsAccessor) ->
    value = valueAccessor()
    bindings = allBindingsAccessor()

    $(element).val ko.utils.unwrapObservable value
    $(element).autocomplete
      minLength : 1
      source    : bindings.source
      select    : (event, ui) ->
        value ui.item.value
        $(element).change()
      focus: (event, ui) ->
        value ui.item.value
        $(element).change()
    $(element).select()

  update: (element, valueAccessor) ->
    $(element).val ko.utils.unwrapObservable valueAccessor()
