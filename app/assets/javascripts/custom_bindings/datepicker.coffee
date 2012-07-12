ko.bindingHandlers.datePicker =
  init: (element, valueAccessor) ->
    value = valueAccessor()

    $(element).val ko.utils.unwrapObservable value
    unless $(element).is '[readonly]'
      $(element).datepicker
        dateFormat: 'yy-mm-dd'
        onSelect: (selectedDate) ->
          value selectedDate
          $(@).datepicker 'hide'
