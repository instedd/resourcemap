ko.bindingHandlers.autocompleteTagField =
  init: (element, valueAccessor, allBindingsAccessor) ->
    value = valueAccessor()
    bindings = allBindingsAccessor()

    $(element).autocompleteTagField
      preset        : value()
      proxy         : $(element).attr 'proxy'
      valueField    : $(element).attr 'valueField'
      displayField  : $(element).attr 'displayField'
      minChar       : $(element).attr('minChar') ? 3

    $(element).change ->
      value $.map(JSON.parse(@value), (item) -> new bindings.objectType(item))
        
  update: (element, valueAccessor) ->
    $(element).val ko.utils.unwrapObservable valueAccessor()
