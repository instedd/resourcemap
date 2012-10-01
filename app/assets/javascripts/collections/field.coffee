onCollections ->

  # A Layer field
  class @Field
    constructor: (data) ->
      @esCode = "#{data.id}"
      @code = data.code
      @name = data.name
      @kind = data.kind
      @showInGroupBy = @kind in ['select_one', 'select_many', 'hierarchy']
      @writeable = data?.writeable

      @value = ko.observable()
      @hasValue = ko.computed => @value() && (if @kind == 'select_many' then @value().length > 0 else @value())

      if @kind == 'date'
        @valueUI =  ko.computed
         read: =>  @valueUIFor(@value())
         write: (value) =>
           @value(@valueUIFrom(value))
      else
        @valueUI = ko.computed => @valueUIFor(@value())

      if @kind in ['select_one', 'select_many']
        @options = if data.config?.options?
                     $.map data.config.options, (x) => new Option x
                   else
                     []
        @optionsIds = $.map @options, (x) => x.id
        @hierarchy = @options

      if @kind == 'hierarchy'
        @hierarchy = data.config?.hierarchy

      @buildHierarchyItems() if @hierarchy?

      if @kind == 'select_many'
        @filter = ko.observable('') # The text for filtering options in a select_many
        @remainingOptions = ko.computed =>
          option.selected(false) for option in @options
          remaining = if @value()
            @options.filter((x) => @value()?.indexOf(x.id) == -1 && x.label.toLowerCase().indexOf(@filter().toLowerCase()) == 0)
          else
            @options
          remaining[0].selected(true) if remaining.length > 0
          remaining
      else
        @filter = ->

      @editing = ko.observable false
      @expanded = ko.observable false # For select_many

    codeForLink: (api = false) =>
      if api then @code else @esCode

    # The value of the UI.
    # If it's a select one or many, we need to get the label from the option code.
    valueUIFor: (value) =>
      if @kind == 'select_one'
        if value then @labelFor(value) else ''
      else if @kind == 'select_many'
        if value then $.map(value, (x) => @labelFor(x)).join(', ') else ''
      else if @kind == 'hierarchy'
        if value then @fieldHierarchyItemsMap[value] else ''
      else if @kind == 'date'
        if value then @datePickerFormat(new Date(value))
      else if @kind == 'site'
        name =  window.model.currentCollection()?.findSiteNameById(value)
        if value && name then name
      else
        value

    valueUIFrom: (value) =>
      if @kind == 'date'
        @valueFromDateUI(value)
      else
        value

    valueFromDateUI: (value) =>
      (new Date(value)).toISOString()

    datePickerFormat: (date) =>
      date.getMonth() + 1 + '/' + date.getDate() + '/' + date.getFullYear()

    buildHierarchyItems: =>
      @fieldHierarchyItemsMap = {}
      @fieldHierarchyItems = ko.observableArray $.map(@hierarchy, (x) => new FieldHierarchyItem(@, x))

    edit: =>
      if !window.model.currentCollection()?.currentSnapshot
        @originalValue = @value()
        @editing(true)
        window.model.initDatePicker (dateText) =>
          @value(dateText)
          @save()

    keyPress: (field, event) =>
      switch event.keyCode
        when 13 then @save()
        when 27 then @exit()
        else true

    exit: =>
      @value(@originalValue) if @originalValue?
      @editing(false)
      @filter('')
      delete @originalValue

    save: =>
      @editing(false)
      @filter('')
      window.model.editingSite().updateProperty(@esCode, @value())
      delete @originalValue

    closeDatePickerAndSave: =>
      if $('#ui-datepicker-div:visible').length == 0
        @save()

    selectOption: (option) =>
      @value([]) unless @value()
      @value().push(option.id)
      @value.valueHasMutated()
      @filter('')

    removeOption: (optionId) =>
      @value([]) unless @value()
      @value(arrayDiff(@value(), [optionId]))
      @value.valueHasMutated()

    expand: => @expanded(true)

    filterKeyDown: (model, event) =>
      switch event.keyCode
        when 13 # Enter
          for option, i in @remainingOptions()
            if option.selected()
              @selectOption(option)
              break
          false
        when 38 # Up
          for option, i in @remainingOptions()
            if option.selected() && i > 0
              option.selected(false)
              @remainingOptions()[i - 1].selected(true)
              break
          false
        when 40 # Down
          for option, i in @remainingOptions()
            if option.selected() && i != @remainingOptions().length - 1
              option.selected(false)
              @remainingOptions()[i + 1].selected(true)
              break
          false
        else
          true

    labelFor: (id) =>
      for option in @options
        if option.id == id
          return option.label
      null

    # In the table view, use a fixed size width for each property column,
    # which depends on the length of the name.
    suggestedWidth: =>
      if @name.length < 10
        '100px'
      else
        "#{20 + @name.length * 8}px"

    isPluginKind: => -1 isnt PLUGIN_FIELDS.indexOf @kind
