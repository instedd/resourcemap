window.arrayDiff = (array1, array2) -> array1.filter (i) -> array2.indexOf(i) < 0

Array.prototype.any ?= (f) ->
  (return true if f x) for x in @
  return false

Array.prototype.all ?= (f) ->
  (return false if not f x) for x in @
  return true
