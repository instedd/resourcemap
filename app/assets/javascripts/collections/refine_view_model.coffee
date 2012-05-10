$(-> if $('#collections-main').length > 0

  class window.RefineViewModel
    @constructorRefineViewModel: ->
      @showingRefinePopup = ko.observable(false)
      @expandedRefineProperty = ko.observable()
      @expandedRefinePropertyOperator = ko.observable()
      @expandedRefinePropertyValue = ko.observable()
      @filters = ko.observableArray([])

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
      event.stopPropagation()

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
      @filters.push(new FilterByLastHour())
      @toggleRefinePopup()

    @filterByLastDay: ->
      @filters.push(new FilterByLastDay())
      @toggleRefinePopup()

    @filterByLastWeek: ->
      @filters.push(new FilterByLastWeek())
      @toggleRefinePopup()

    @filterByLastMonth: ->
      @filters.push(new FilterByLastMonth())
      @toggleRefinePopup()

    @filterByProperty: ->
      return if $.trim(@expandedRefinePropertyValue()).length == 0

      field = @currentCollection().findFieldByCode @expandedRefineProperty()
      if field.kind() == 'text'
        @filters.push(new FilterByTextProperty(field.code(), field.name(), @expandedRefinePropertyValue()))
      else if field.kind() == 'numeric'
        @filters.push(new FilterByNumericProperty(field.code(), field.name(), @expandedRefinePropertyOperator(), @expandedRefinePropertyValue()))
      else if field.kind() == 'select_one' || field.kind() == 'select_many'
        valueLabel = (option for option in field.options() when option.code() == @expandedRefinePropertyValue())[0].label()
        @filters.push(new FilterBySelectProperty(field.code(), field.name(), @expandedRefinePropertyValue(), valueLabel))

      @toggleRefinePopup()

    @expandedRefinePropertyValueKeyPress: (model, event) ->
      switch event.keyCode
        when 13 then @filterByProperty()
        else true
)
