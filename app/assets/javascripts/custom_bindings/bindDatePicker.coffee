ko.bindingHandlers.bindDatePicker =
  init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
    if $.fn.datepicker 
      $(".ux-datepicker:not([readonly])")
        .click ->
          $(element).datepicker "show"
        .datepicker({"dateFormat": "yy-mm-dd" })

