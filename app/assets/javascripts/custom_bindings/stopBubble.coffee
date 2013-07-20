ko.bindingHandlers.stopBubble = init: (element) ->
  ko.utils.registerEventHandler element, "click", (event) ->
    event.cancelBubble = true
    event.stopPropagation()  if event.stopPropagation
