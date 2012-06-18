ko.bindingHandlers.autocompleteTagField =
  init: (element, valueAccessor,allBindingsAccessor) ->
    objects = valueAccessor()
    allBindings = allBindingsAccessor()
    minChar = $(element).attr('minChar') || 3
    $(element).autocompleteTagField {
      preset: [],
      proxy: $(element).attr('proxy'),
      valueField: $(element).attr('valueField'),
      displayField: $(element).attr('displayField'),
      minChar: minChar
    }

    $(element).change -> 
      objects $.map(JSON.parse(@value), (item) ->
        new allBindings.objectType(item))

