String::toDate = ->
  date = new Date @toString()
  if date and date.toString() isnt 'Invalid Date' then date else null


String.format = (value, formatLength, leadingChar = '0') ->
  result = value.toString()
  while result.length < formatLength
    result = "#{leadingChar}#{result}"
  result

String::titleize = ->
  no_underscores = @replace '_', ' '
  words = no_underscores.split ' '
  words = _.map words, (w) -> w.charAt(0).toUpperCase() + w.slice(1)
  words.join ' '
