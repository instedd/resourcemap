onCollections ->

  class @Filter
    isDateFilter: => false
    isLocationMissingFilter: => false

  class @FilterMaybeEmpty extends Filter
    setQueryParams: (options, api = false) =>
      if @operator == 'empty'
        options[@field.codeForLink(api)] = "="
      else
        @setQueryParamsNonEmpty(options, api)

    description: =>
      if @operator == 'empty'
        "where #{@field.name} has no value"
      else
        @descriptionNonEmpty()

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

  class @FilterBySiteProperty extends FilterMaybeEmpty
    constructor: (field, operator, name, id) ->
      @field = field
      @operator = operator
      @name = name
      @id = id

    setQueryParamsNonEmpty: (options, api = false) =>
      options[@field.codeForLink(api)] = "#{@id}"

    descriptionNonEmpty: =>
      "where #{@field.name} is \"#{@name}\""

  class @FilterByTextProperty extends FilterMaybeEmpty
    constructor: (field, operator, value) ->
      @field = field
      @operator = operator
      @value = value

    setQueryParamsNonEmpty: (options, api = false) =>
      options[@field.codeForLink(api)] = "~=#{@value}"

    descriptionNonEmpty: =>
      "where #{@field.name} starts with \"#{@value}\""

  class @FilterByNumericProperty extends FilterMaybeEmpty
    constructor: (field, operator, value) ->
      @field = field
      @operator = operator
      @value = value

    setQueryParamsNonEmpty: (options, api = false) =>
      code = @field.codeForLink(api)
      options[code] = {} if not options[code]
      options[code][@operator] = @value

    descriptionNonEmpty: =>
      str = "where #{@field.name} "
      switch @operator
        when '=' then str += " equals "
        when '<' then str += " is less than "
        when '<=' then str += " is less than or equal to "
        when '>' then str += " is greater than "
        when '>=' then str += " is greater than or equal to "
      str += "#{@value}"

  class @FilterByYesNoProperty extends Filter
    constructor: (field, value) ->
      @field = field
      @value = value

    setQueryParams: (options, api = false) =>
      code = @field.codeForLink(api)
      options[code] = if @value == 'yes' then 'yes' else 'no'

    description: =>
      if @value == 'yes'
        " is 'yes'"
      else
        " is 'no'"

  class @FilterByDateProperty extends FilterMaybeEmpty
    constructor: (field, operator, valueFrom, valueTo) ->
      @field = field
      @operator = operator
      @valueTo = valueTo
      @valueFrom = valueFrom

    setQueryParamsNonEmpty: (options, api = false) =>
      options[@field.codeForLink(api)]  = "=#{@valueFrom},#{@valueTo}"

    descriptionNonEmpty: =>
      "where #{@field.name} is between #{@valueFrom} and #{@valueTo}"

  class @FilterByHierarchyProperty extends Filter
    constructor: (field, operator, value, valueLabel) ->
      @field = field
      @operator = operator
      @value = value
      @valueLabel = valueLabel

    setQueryParams: (options, api = false) =>
      code = @field.codeForLink(api)
      options[code] = {} if not options[code]
      options[code][@operator] = @value

    description: =>
      "with #{@field.name} #{@operator} \"#{@valueLabel}\""

  class @FilterBySelectProperty extends Filter
    constructor: (field, value, valueLabel) ->
      @field = field
      @value = value
      @valueLabel = valueLabel

    setQueryParams: (options, api = false) =>
      options[@field.codeForLink(api)] = @value

    description: =>
      if @valueLabel
        "where #{@field.name} is \"#{@valueLabel}\""
      else
        "where #{@field.name} has no value"
