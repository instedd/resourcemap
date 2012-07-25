onCollections ->

  class @RefineViewModel
    @constructorRefineViewModel: ->
      @showingRefinePopup = ko.observable(false)
      @expandedRefineProperty = ko.observable()
      @expandedRefinePropertyOperator = ko.observable()
      @expandedRefinePropertyValue = ko.observable()
      @filters = ko.observableArray([])

    @hideRefinePopup: ->
      @showingRefinePopup(false)

    @filteringByProperty: (filterClass) ->
      @filters().any (f) -> f instanceof filterClass

    @filteringByPropertyAndValue: (filterClass, value) ->
      @filters().any (f) -> f instanceof filterClass && f.value == value

    @filteringByPropertyAndValueAndOperator: (filterClass, operator, value) ->
      @filters().any (f) -> f instanceof filterClass && f.value == value && f.operator == operator

    @filteringByPropertyAndSelectProperty: (filterClass, value, label) ->
      @filters().any (f) -> f instanceof filterClass && f.value == value && f.valueLabel == label

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

    @filterByProperty: ->
      return if $.trim(@expandedRefinePropertyValue()).length == 0

      field = @currentCollection().findFieldByEsCode @expandedRefineProperty()
      if field.kind == 'text'
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

      @hideRefinePopup()

    @expandedRefinePropertyValueKeyPress: (model, event) ->
      switch event.keyCode
        when 13 then @filterByProperty()
        else true
