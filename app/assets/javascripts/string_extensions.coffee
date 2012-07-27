String::isDate = -> !isNaN Date.parse @

String.format = (value, formatLength, leadingChar = '0') ->
  result = value.toString()
  while result.length < formatLength
    result = "#{leadingChar}#{result}"
  result