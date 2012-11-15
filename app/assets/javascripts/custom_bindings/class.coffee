ko.bindingHandlers["class"] =
  update: (element, valueAccessor) ->
    $(element).removeClass element["__ko__previousClassValue__"] if element["__ko__previousClassValue__"]
    value = ko.utils.unwrapObservable(valueAccessor())
    $(element).addClass value
    element["__ko__previousClassValue__"] = value