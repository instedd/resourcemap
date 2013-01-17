# Defining new methods in array class causes knockout to fail

window.arrayDiff = (array1, array2) -> array1.filter (i) -> array2.indexOf(i) < 0

window.arrayAny ?= (a, f) ->
  (return true if f x) for x in a
  return false

window.arrayAll ?= (a, f) ->
  (return false if not f x) for x in a
  return true

window.toSentence ?= (array) ->
  if array.length < 2
    return array.toString()
  last = array[array.length-1]
  all_but_last = array.slice(0, -1)
  all_but_last.join(', ') + ' and ' + last
