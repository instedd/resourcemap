window.arrayDiff = (array1, array2) -> array1.filter (i) -> array2.indexOf(i) < 0

window.arrayAny ?= (a, f) ->
  (return true if f x) for x in a
  return false

window.arrayAll ?= (a, f) ->
  (return false if not f x) for x in a
  return true
