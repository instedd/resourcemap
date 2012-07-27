Date::strftime = (format) ->
  format = format.replace key, value for key, value of @getParts()
  format

Date::getParts = ->
  month = @getMonth() + 1
  result =
    '%Y' : @getFullYear().toString()
    '%m' : String.format month, 2
    '%d' : String.format @getDate(), 2
    '%H' : String.format @getHours(), 2
    '%M' : String.format @getMinutes(), 2
    '%S' : String.format @getSeconds(), 2

Date.today = ->
  now = new Date(); today = new Date now.getFullYear(), now.getMonth(), now.getDate()
