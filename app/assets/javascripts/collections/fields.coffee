$(-> if $('#collections-main').length > 0

  class window.Layer
    constructor: (data) ->
      @name = ko.observable data?.name
      @fields = ko.observableArray($.map(data.fields, (x) => new Field(x)))
      @expanded = ko.observable(true)

    toggleExpand: =>
      @expanded(!@expanded())

  # A Layer field
  class window.Field
    constructor: (data) ->
      @code = ko.observable data?.code
      @name = ko.observable data?.name
      @kind = ko.observable data?.kind
      @writeable = ko.observable data?.writeable
      @options = if data.config?.options?
                   ko.observableArray($.map(data.config.options, (x) => new Option(x)))
                 else
                   ko.observableArray()
      @optionsCodes = ko.computed => $.map(@options(), (x) => x.code())
      @value = ko.observable()
      @hasValue = ko.computed => @value() && (if @kind() == 'select_many' then @value().length > 0 else @value())
      @valueUI = ko.computed => @valueUIFor(@value())
      @remainingOptions = ko.computed =>
        if @value()
          @options().filter((x) => @value().indexOf(x.code()) == -1)
        else
          @options()

      @editing = ko.observable false
      @expanded = ko.observable false # For select_many

    # The value of the UI.
    # If it's a select one or many, we need to get the label from the option code.
    valueUIFor: (value) =>
      if @kind() == 'select_one'
        if value then @labelFor(value) else ''
      else if @kind() == 'select_many'
        if value then $.map(value, (x) => @labelFor(x)).join(', ') else ''
      else
        value

    edit: =>
      @originalValue = @value()
      @editing(true)

    keyPress: (field, event) =>
      switch event.keyCode
        when 13 then @save()
        when 27 then @exit()
        else true

    exit: =>
      @value(@originalValue) if @originalValue?
      @editing(false)
      delete @originalValue

    save: =>
      @editing(false)
      window.model.editingSite().updateProperty(@code(), @value())
      delete @originalValue

    selectOption: (option) =>
      @value([]) unless @value()
      @value().push(option.code())
      @value.valueHasMutated()

    removeOption: (optionCode) =>
      @value([]) unless @value()
      @value(@value().diff([optionCode]))
      @value.valueHasMutated()

    expand: => @expanded(true)

    labelFor: (code) =>
      for option in @options()
        if option.code() == code
          return option.label()
      null

    # In the table view, use a fixed size width for each property column,
    # which depends on the length of the name.
    suggestedWidth: =>
      if @name().length < 10
        '100px'
      else
        "#{20 + @name().length * 8}px"

  class window.Option
    constructor: (data) ->
      @code = ko.observable(data?.code)
      @label = ko.observable(data?.label)

)
