onCollections ->

  # A Layer field
  class @Field
    constructor: (data, nextValueProvider) ->
      @nextValueProvider = nextValueProvider

      @esCode = "#{data.id}"
      @code = data.code
      @name = data.name
      @kind = data.kind
      @showInGroupBy = @kind in ['select_one', 'select_many', 'hierarchy']
      @writeable = @originalWriteable = data?.writeable

      @allowsDecimals = ko.observable data?.config?.allows_decimals == 'true'

      @value = ko.observable()

      @hasValue = ko.computed =>
        if @kind == 'yes_no'
          true
        else
          @value() && (if @kind == 'select_many' then @value().length > 0 else @value())

      @defaultValue = ko.observable()

      @valueUI = ko.computed
        read: =>
          @valueUIFor(@value())
        write: (value) =>
          if !value
            new_value = @defaultValue() || ''
            @value(new_value)
            @value.valueHasMutated()
          else
            new_value = @valueUIFrom(value)
            if new_value
              @value(new_value)
              @value.valueHasMutated()

      if @kind in ['select_one', 'select_many']
        @options = if data.config?.options?
                    $.map data.config.options, (x) => new Option x
                  else
                    []
        @optionsIds = $.map @options, (x) => x.id

        # Add the 'no value' option
        @optionsIds.unshift('')
        @optionsUI = [new Option {id: '', label: '(no value)' }].concat(@options)
        @optionsUIIds = $.map @optionsUI, (x) => x.id

        @hierarchy = @options

      if @kind == 'date'
        @format =  data.config?.format

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
            @options.filter((x) => x.label.toLowerCase().indexOf(@filter().toLowerCase()) == 0)
          remaining[0].selected(true) if remaining.length > 0
          remaining
      else
        @filter = ->

      @editing = ko.observable false
      @expanded = ko.observable false # For select_many
      @errorMessage = ko.observable ""
      @error = ko.computed => !!@errorMessage()

    setValueFromSite: (value) =>
      if @kind == 'date' && $.trim(value).length > 0
        # Value from server comes with utc time zone and creating a date here gives one
        # with the client's (browser) time zone, so we convert it back to utc

        # Value first comes from server comes with a different format than next times,
        # and for that reason an "if" statement is used.

        if @format == "dd_mm_yyyy"
          [day, month, year] = value.split('/')
        else
          [month, day, year] = value.split('/')
        date = new Date(year,month,day)

        if(date.notValid())
          date = new Date(value)
          date.setTime(date.getTime() + date.getTimezoneOffset() * 60000)
          value = @datePickerFormat(date)

      value = '' unless value

      @value(value)

    codeForLink: (api = false) =>
      if api then @code else @esCode

    yearIsCorrect: (year) =>
      maxYear = Date.today().getFullYear() + 50
      minYear = 1800
      return minYear <= year <= maxYear

    dateIsCorrect: (month,day,year) =>
      return (month && day && year && @yearIsCorrect(year) && month <= 12 && day <= 31)

    # The value of the UI.
    # If it's a select one or many, we need to get the label from the option code.
    valueUIFor: (value) =>
      if @kind == 'yes_no'
        if value then 'yes' else 'no'
      else if @kind == 'select_one'
        if value then @labelFor(value) else ''
      else if @kind == 'select_many'
        if value then $.map(value, (x) => @labelFor(x)).join(', ') else ''
      else if @kind == 'hierarchy'
        if value then @fieldHierarchyItemsMap[value] else ''
      else if @kind == 'site'
        name = window.model.currentCollection()?.findSiteNameById(value)
        if name && value then name else value
      else if @kind == 'image_gallery'
        # FIXME: valueUIFor seems to always return a string - shouldn't we move the <img>s to other property?
        if value then "<img src=\"#{value.images[0].image}\" /><img src=\"#{value.images[0].image}\" /><img src=\"#{value.images[0].image}\" />" else 'No hay nada, che'
      else if @kind == 'date'
        if value
          if @format == "dd_mm_yyyy"
            [day, month, year] = value.split('/')
          else
            [month, day, year] = value.split('/')
          if !@dateIsCorrect(month,day,year)
            return value
          else
            formatted_value = "#{month}/#{day}/#{year}"
            date = new Date(formatted_value)
            #Extra check. It's necessary, for example, when user
            #is changin values on the fly.
            if(date.notValid())
              return value
            else
              date.setTime(date.getTime() + date.getTimezoneOffset() * 60000)
              @datePickerFormat(date)
        else
          ""
      else
        if value then value else ''

    valueUIFrom: (value) =>
      if @kind == 'site'
        if site = window.model.currentCollection()?.findSiteIdByName(value)
          site
        else
          value
      else
        value

    datePickerFormat: (date) =>
      if @format == "dd_mm_yyyy"
        date.getDate() + '/' + (date.getMonth() + 1) + '/' + date.getFullYear()
      else
        date.getMonth() + 1 + '/' + date.getDate() + '/' + date.getFullYear()

    buildHierarchyItems: =>
      @fieldHierarchyItemsMap = {}
      @fieldHierarchyItems = ko.observableArray $.map(@hierarchy, (x) => new FieldHierarchyItem(@, x))
      @fieldHierarchyItems.unshift new FieldHierarchyItem(@, {id: '', name: '(no value)'})

    closeHierarchyItems: =>
      for item in @fieldHierarchyItems()
        item.close()

    # Notifies the field that it should be prepared for edition
    # Returns whether the field has actually entered edit mode or not
    onEnteredEditMode: =>
      return false if window.model.currentCollection()?.currentSnapshot
      @originalValue = @value() unless @error()

      # For select many, if it's an array we need to duplicate it
      if @kind == 'select_many' && typeof(@) == 'object'
        @originalValue = @originalValue.slice(0)
      if @kind == 'identifier'
        if not @value() then @value(@nextValue())

      return true

    hasChanged: =>
      return ! _.isEqual(@originalValue, @value())

    edit: =>
      return if not @onEnteredEditMode()
      @editing(true)
      optionsDatePicker = {defaultDate: @value()}
      optionsDatePicker.onSelect = (dateText) =>
        @valueUI(dateText)
        @save()
      optionsDatePicker.onClose = () =>
        @save()
      window.model.initDatePicker(optionsDatePicker)
      window.model.initAutocomplete()

    keyPress: (field, event) =>
      switch event.keyCode
        when 13 then @save()
        when 27 then @exit()
        else true

    exit: =>
      @value(@originalValue)
      @editing(false)
      @filter('')
      delete @originalValue

    save: =>
      window.model.editingSite().updateProperty(@esCode, @value())
      if !@error()
        @editing(false)
        @filter('')
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
      for option in @optionsUI
        if option.id == id
          return option.label
      null

    codeForOption: (value, api = false) =>
      if @options and api
        option = @options.filter (element) => element.id == value
        if option.length > 0 then option[0].code else value
      else
        value

    # In the table view, use a fixed size width for each property column,
    # which depends on the length of the name.
    suggestedWidth: =>
      "#{Math.max(100, 30 + @name.length * 8)}px"

    isPluginKind: => -1 isnt PLUGIN_FIELDS.indexOf @kind

    exitEditing: ->
      @editing(false)
      @writeable = @originalWriteable

    nextValue: =>
      @nextValueProvider(@esCode)
