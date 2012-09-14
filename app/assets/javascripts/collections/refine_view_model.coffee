onCollections ->

  class @RefineViewModel
    @constructor: ->
      @showingRefinePopup = ko.observable(false)
      @expandedRefineProperty = ko.observable()
      @expandedRefinePropertyOperator = ko.observable()
      @expandedRefinePropertyValue = ko.observable()
      @expandedRefinePropertyDateTo = ko.observable()
      @expandedRefinePropertyDateFrom = ko.observable()
      @filters = ko.observableArray([])

    @hideRefinePopup: ->
      @showingRefinePopup(false)

    @filteringByProperty: (filterClass) ->
      window.arrayAny(@filters(), (f) -> f instanceof filterClass)

    @filteringByPropertyAndValue: (filterClass, value) ->
      window.arrayAny(@filters(), (f) -> f instanceof filterClass && f.value == value)

    @filteringByPropertyAndValueAndOperator: (filterClass, operator, value) ->
      window.arrayAny(@filters(), (f) -> f instanceof filterClass && f.value == value && f.operator == operator)

    @filteringByPropertyAndSelectProperty: (filterClass, value, label) ->
      window.arrayAny(@filters(), (f) -> f instanceof filterClass && f.value == value && f.valueLabel == label)

    @filteringByDatePropertyRange: (filterClass, field, valueFrom, valueTo) ->
      window.arrayAny(@filters(), (f) -> f instanceof filterClass && f.field == field && f.valueFrom == valueFrom && f.valueTo == valueTo)


    @toggleRefinePopup: (model, event) ->
      @showingRefinePopup(!@showingRefinePopup())
      if @showingRefinePopup()
        $refine = $('.refine')
        refineOffset = $refine.offset()
        $('.refine-popup').offset(top: refineOffset.top + $refine.outerHeight(), left: refineOffset.left)
        false
      else
        @expandedRefineProperty(null)
        @expandedRefinePropertyOperator('=')
        @expandedRefinePropertyValue('')
      event.stopPropagation() if event

    @toggleRefineProperty: (property) ->
      @expandedRefinePropertyOperator('=')
      @expandedRefinePropertyValue('')
      if @expandedRefineProperty() == property
        @expandedRefineProperty(null)
      else
        @expandedRefineProperty(null) # Needed because sometimes we get a stack overflow (can't find the reason to it)
        @expandedRefineProperty(property)
        window.model.initDatePicker (p, inst) =>
          id = inst.id
          $("##{id}").change()


    @filterDescription: (filter) ->
      if @filters()[0] == filter
        "Show sites #{filter.description()}"
      else
        filter.description()

    @removeFilter: (filter) ->
      @filters.remove filter

    @filterByLastHour: ->
      if(!@filteringByProperty(FilterByLastHour))
        @filters.push(new FilterByLastHour())
      @hideRefinePopup()

    @filterByLastDay: ->
      if(!@filteringByProperty(FilterByLastDay))
        @filters.push(new FilterByLastDay())
      @hideRefinePopup()

    @filterByLastWeek: ->
      if(!@filteringByProperty(FilterByLastWeek))
        @filters.push(new FilterByLastWeek())
      @hideRefinePopup()

    @filterByLastMonth: ->
      if(!@filteringByProperty(FilterByLastMonth))
        @filters.push(new FilterByLastMonth())
      @hideRefinePopup()

    @filterByLocationMissing: ->
      if(!@filteringByProperty(FilterByLocationMissing))
        @filters.push(new FilterByLocationMissing())
      @hideRefinePopup()

    @anyDateParamenterAbsent: ->
      ($.trim(@expandedRefinePropertyDateTo()).length == 0 || $.trim(@expandedRefinePropertyDateFrom()).length == 0)

    @anyDateParameterWithInvalidFormat: ->
      try
        $.datepicker.parseDate('mm/dd/yy', @expandedRefinePropertyDateTo())
        $.datepicker.parseDate('mm/dd/yy', @expandedRefinePropertyDateFrom())
        false
      catch e
        true

    @notValueSelected: ->
      $.trim(@expandedRefinePropertyValue()).length == 0 && (@anyDateParamenterAbsent() || @anyDateParameterWithInvalidFormat())

    @filterByProperty: ->
      return if @notValueSelected()
      field = @currentCollection().findFieldByEsCode @expandedRefineProperty()
      if field.kind == 'text' or field.kind == 'user' or field.isPluginKind()
        if(!@filteringByPropertyAndValue(FilterByTextProperty, @expandedRefinePropertyValue()))
          @filters.push(new FilterByTextProperty(field, @expandedRefinePropertyValue()))
      else if field.kind == 'numeric'
        if(!@filteringByPropertyAndValueAndOperator(FilterByNumericProperty, @expandedRefinePropertyOperator(), @expandedRefinePropertyValue()))
          @filters.push(new FilterByNumericProperty(field, @expandedRefinePropertyOperator(), @expandedRefinePropertyValue()))
      else if field.kind in ['select_one', 'select_many']
        @expandedRefinePropertyValue(parseInt(@expandedRefinePropertyValue()))
        valueLabel = (option for option in field.options when option.id == @expandedRefinePropertyValue())[0].label
        if(!@filteringByPropertyAndSelectProperty(FilterBySelectProperty, @expandedRefinePropertyValue(), valueLabel))
          @filters.push(new FilterBySelectProperty(field, @expandedRefinePropertyValue(), valueLabel))
      else if field.kind == 'date'
        if(!@filteringByDatePropertyRange(FilterByDateProperty, field, @expandedRefinePropertyDateFrom(), @expandedRefinePropertyDateTo()))
          @filters.push(new FilterByDateProperty(field, @expandedRefinePropertyDateFrom(), @expandedRefinePropertyDateTo()))
          @expandedRefinePropertyDateFrom(null)
          @expandedRefinePropertyDateTo(null)

      @expandedRefineProperty(null)
      @hideRefinePopup()

    @expandedRefinePropertyValueKeyPress: (model, event) ->
      switch event.keyCode
        when 13 then @filterByProperty()
        else true
