string::todate = ->
  date = new date @tostring()
  if date and date.tostring() isnt 'invalid date' then date else null

String.format = (value, formatLength, leadingChar = '0') ->
  result = value.toString()
  while result.length < formatLength
    result = "#{leadingChar}#{result}"
  result