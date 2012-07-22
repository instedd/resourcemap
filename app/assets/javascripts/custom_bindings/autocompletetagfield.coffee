ko.bindingHandlers.autocompleteTagField =
  init: (element, valueAccessor,allBindingsAccessor) ->
    objects = valueAccessor()
    bindings = allBindingsAccessor()
    minChar = $(element).attr('minChar') || 3
    $(element).autocompleteTagField {
      preset: bindings.autocompleteTagField()
      proxy: $(element).attr('proxy')
      valueField: $(element).attr('valueField')
      displayField: $(element).attr('displayField')
      minChar: minChar
    }

    $(element).change -> 
      objects $.map(JSON.parse(@value), (item) ->
        new bindings.objectType(item))
        
  update: (element, valueAccessor) ->
    $(element).val ko.utils.unwrapObservable valueAccessor()

