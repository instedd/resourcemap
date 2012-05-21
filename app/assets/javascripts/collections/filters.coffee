onCollections ->

  class @Filter
    isDateFilter: => false

  class @FilterByDate
    isDateFilter: => true

  class @FilterByLastHour extends FilterByDate
    setQueryParams: (options) =>
      options.updated_since = 'last_hour'

    description: => "updated within the last hour"


  class @FilterByLastDay extends FilterByDate
    setQueryParams: (options) =>
      options.updated_since = 'last_day'

    description: => "updated within the last day"

  class @FilterByLastWeek extends FilterByDate
    setQueryParams: (options) =>
      options.updated_since = 'last_week'

    description: => "updated within the last week"

  class @FilterByLastMonth extends FilterByDate
    setQueryParams: (options) =>
      options.updated_since = 'last_month'

    description: => "updated within the last month"

  class @FilterByTextProperty extends Filter
    constructor: (esCode, label, value) ->
      @esCode = esCode
      @label = label
      @value = value

    setQueryParams: (options) =>
      options[@esCode] = @value

    description: => "where #{@label} contains \"#{@value}\""

  class @FilterByNumericProperty extends Filter
    constructor: (esCode, label, operator, value) ->
      @esCode = esCode
      @label = label
      @operator = operator
      @value = value

    setQueryParams: (options) =>
      options[@esCode] = "#{@operator}#{@value}"

    description: =>
      str = "where #{@label} "
      switch @operator
        when '=' then str += " equals "
        when '<' then str += " is less than "
        when '<=' then str += " is less than or equal to "
        when '>' then str += " is greater than "
        when '>=' then str += " is greater than or equal to "
      str += "#{@value}"

  class @FilterBySelectProperty extends Filter
    constructor: (esCode, label, value, valueLabel) ->
      @esCode = esCode
      @label = label
      @value = value
      @valueLabel = valueLabel

    setQueryParams: (options) =>
      options[@esCode] = @value

    description: =>
      "where #{@label} is \"#{@valueLabel}\""
