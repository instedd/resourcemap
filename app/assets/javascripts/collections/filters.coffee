onCollections ->

  class @Filter
    isDateFilter: => false
    isLocationMissingFilter: => false

  class @FilterByDate
    isDateFilter: => true

  class @FilterByLastHour extends FilterByDate
    setQueryParams: (options, api = false) =>
      options.updated_since = 'last_hour'

    description: => "updated within the last hour"

  class @FilterByLastDay extends FilterByDate
    setQueryParams: (options, api = false) =>
      options.updated_since = 'last_day'

    description: => "updated within the last day"

  class @FilterByLastWeek extends FilterByDate
    setQueryParams: (options, api = false) =>
      options.updated_since = 'last_week'

    description: => "updated within the last week"

  class @FilterByLastMonth extends FilterByDate
    setQueryParams: (options, api = false) =>
      options.updated_since = 'last_month'

    description: => "updated within the last month"

  class @FilterByLocationMissing extends Filter
    setQueryParams: (options, api = false) =>
        options.location_missing = true

    description: => "with location missing"

  class @FilterByTextProperty extends Filter
    constructor: (field, value) ->
      @field = field
      @value = value

    setQueryParams: (options, api = false) =>
      options[@field.codeForLink(api)] = "~=#{@value}"

    description: => "where #{@field.name} starts with \"#{@value}\""

  class @FilterByNumericProperty extends Filter
    constructor: (field, operator, value) ->
      @field = field
      @operator = operator
      @value = value

    setQueryParams: (options, api = false) =>
      options[@field.codeForLink(api)] = "#{@operator}#{@value}"

    description: =>
      str = "where #{@field.name} "
      switch @operator
        when '=' then str += " equals "
        when '<' then str += " is less than "
        when '<=' then str += " is less than or equal to "
        when '>' then str += " is greater than "
        when '>=' then str += " is greater than or equal to "
      str += "#{@value}"

  class @FilterByDateProperty extends Filter
    constructor: (field, valueFrom, valueTo) ->
      @field = field
      @valueTo = valueTo
      @valueFrom = valueFrom

    setQueryParams: (options, api = false) =>
      options["date_field_range"] = "#{@field.codeForLink(api)}:#{@valueFrom},#{@valueTo}"

    description: =>
      "where #{@field.name} is between #{@valueFrom} and #{@valueTo}"

  class @FilterBySelectProperty extends Filter
    constructor: (field, value, valueLabel) ->
      @field = field
      @value = value
      @valueLabel = valueLabel

    setQueryParams: (options, api = false) =>
      options[@field.codeForLink(api)] = @value

    description: =>
      "where #{@field.name} is \"#{@valueLabel}\""
