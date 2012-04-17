$(-> if $('#collections-main').length > 0

  class window.FilterByLastHour
    setOptions: (options) =>
      options.updated_since = 'last_hour'

    description: => "updated within the last hour"

  class window.FilterByLastDay
    setOptions: (options) =>
      options.updated_since = 'last_day'

    description: => "updated within the last day"

  class window.FilterByLastWeek
    setOptions: (options) =>
      options.updated_since = 'last_week'

    description: => "updated within the last week"

  class window.FilterByLastMonth
    setOptions: (options) =>
      options.updated_since = 'last_month'

    description: => "updated within the last month"

  class window.FilterByTextProperty
    constructor: (code, label, value) ->
      @code = code
      @label = label
      @value = value

    setOptions: (options) =>
      options["@#{@code}"] = @value

    description: => "where #{@label} contains \"#{@value}\""

  class window.FilterByNumericProperty
    constructor: (code, label, operator, value) ->
      @code = code
      @label = label
      @operator = operator
      @value = value

    setOptions: (options) =>
      options["@#{@code}"] = "#{@operator}#{@value}"

    description: =>
      str = "where #{@label} "
      switch @operator
        when '=' then str += " equals "
        when '<' then str += " is less than "
        when '<=' then str += " is less than or equal to "
        when '>' then str += " is greater than "
        when '>=' then str += " is greater than or equal to "
      str += "#{@value}"

  class window.FilterBySelectProperty
    constructor: (code, label, value, valueLabel) ->
      @code = code
      @label = label
      @value = value
      @valueLabel = valueLabel

    setOptions: (options) =>
      options["@#{@code}"] = @value

    description: =>
      "where #{@label} is \"#{@valueLabel}\""

)
