onCollections ->

  class @RefineViewModel
    @constructor: ->
      @showingRefinePopup = ko.observable(false)
      @expandedRefineProperty = ko.observable()
      @expandedRefinePropertyOperator = ko.observable()
      @expandedRefinePropertyValue = ko.observable()
      @expandedRefinePropertyDateTo = ko.observable()
      @expandedRefinePropertyDateFrom = ko.observable()
      @expandedRefinePropertyHierarchy = ko.observable()
      @expandedRefinePropertyHierarchy.subscribe (item) -> item?.select()
      @filters = ko.observableArray([])

    @hideRefinePopup: ->
      @showingRefinePopup(false)

    @filteringByProperty: (filterClass) ->
      window.arrayAny(@filters(), (f) -> f instanceof filterClass)

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
      @expandedRefinePropertyHierarchy(null)
      if @expandedRefineProperty() == property
        @expandedRefineProperty(null)
      else
        @expandedRefineProperty(null) # Needed because sometimes we get a stack overflow (can't find the reason to it)
        @expandedRefineProperty(property)
        window.model.initDatePicker (p, inst) =>
          id = inst.id
          $("##{id}").change()
        window.model.initAutocomplete()

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
      @expandedRefinePropertyOperator() != 'empty' && !$.trim(@expandedRefinePropertyValue()) && (@anyDateParamenterAbsent() || @anyDateParameterWithInvalidFormat()) && !@expandedRefinePropertyHierarchy()

    @filterByProperty: ->
      field = @currentCollection().findFieldByEsCode @expandedRefineProperty()
      return if field.kind != 'select_one' && field.kind != 'select_many' && @notValueSelected()

      filter = @filterFor(field)
      if field.kind == 'numeric'
        @addOrReplaceFilter(filter, (f) => f.operator == @expandedRefinePropertyOperator())
      else
        @addOrReplaceFilter(filter)

      @expandedRefineProperty(null)
      @expandedRefinePropertyDateFrom(null)
      @expandedRefinePropertyDateTo(null)
      @expandedRefinePropertyHierarchy(null)
      @hideRefinePopup()

    @addOrReplaceFilter: (filter, extraCondition = -> true) ->
      i = 0
      for f in @filters()
        if f.field == filter.field && extraCondition(f)
          @filters.splice(i, 1, filter)
          break
        i++
      if i == @filters().length
        @filters.push(filter)

    @filterFor: (field) ->
      return new FilterByTextProperty(field, @expandedRefinePropertyOperator(), @expandedRefinePropertyValue()) if field.isPluginKind()
      return switch field.kind
        when 'text', 'user'
          new FilterByTextProperty(field, @expandedRefinePropertyOperator(), @expandedRefinePropertyValue())
        when 'site'
          id = @currentCollection().findSiteIdByName(@expandedRefinePropertyValue())
          new FilterBySiteProperty(field, @expandedRefinePropertyOperator(), @expandedRefinePropertyValue(), id)
        when 'numeric'
          new FilterByNumericProperty(field, @expandedRefinePropertyOperator(), @expandedRefinePropertyValue())
        when 'yes_no'
          new FilterByYesNoProperty(field, @expandedRefinePropertyValue())
        when 'select_one', 'select_many'
          @expandedRefinePropertyValue(parseInt(@expandedRefinePropertyValue()))
          valueLabel = (option for option in field.options when option.id == @expandedRefinePropertyValue())[0]?.label
          new FilterBySelectProperty(field, @expandedRefinePropertyValue(), valueLabel)
        when 'date'
          new FilterByDateProperty(field, @expandedRefinePropertyOperator(), @expandedRefinePropertyDateFrom(), @expandedRefinePropertyDateTo())
        when 'hierarchy'
          new FilterByHierarchyProperty(field, 'under', @expandedRefinePropertyHierarchy().id, @expandedRefinePropertyHierarchy().name)
        else
          throw "Unknown field kind: #{field.kind}"

    @expandedRefinePropertyValueKeyPress: (model, event) ->
      switch event.keyCode
        when 13 then @filterByProperty()
        else true
