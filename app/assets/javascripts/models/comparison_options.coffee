$ ->
  module 'rm'

  rm.ComparisonOptions =

    getText: (key) ->
      for type, comparison of @ when type != 'getText'
        for code, text of comparison
          return text if code == key

    numeric:
      lt: 'is less than'
      gt: 'is greater than'

    text:
      eq: 'is equals to'
      con: 'contains'
