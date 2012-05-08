@initLayers = ->
  class Layer
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @public = ko.observable data?.public
      @ord = ko.observable data?.ord
      if data?.fields
        @fields = ko.observableArray($.map(data.fields, (x) -> new Field(@, x)))
      else
        @fields = ko.observableArray([])
      @hasFocus = ko.observable(false)
      @nameError = ko.computed => if @hasName() then null else "the layer's Name is missing"
      @fieldsError = ko.computed =>
        return "the layer must have at least one field" if @fields().length == 0

        codes = []
        names = []

        # Check that the name and code are not duplicated
        for field in @fields()
          field_error = field.error()
          return field_error if field_error
          return "duplicated field name '#{field.name()}'" if names.indexOf(field.name()) >= 0
          return "duplicated field code '#{field.code()}'" false if codes.indexOf(field.code()) >= 0
          names.push field.name()
          codes.push field.code()

        # Now check that the names and codes don't apper in other layers
        if window.model
          for layer in window.model.layers() when layer != @
            for field in layer.fields()
              return "a field with name '#{field.name()}' already exists in the layer named #{layer.name()}" if names.indexOf(field.name()) >= 0
              return "a field with code '#{field.code()}' already exists in the layer named #{layer.name()}"  if codes.indexOf(field.code()) >= 0

        null
      @error = ko.computed => @nameError() || @fieldsError()
      @valid = ko.computed => !@error()

    hasName: => $.trim(@name()).length > 0

    toJSON: =>
      id: @id()
      name: @name()
      ord: @ord()
      public: @public()
      fields_attributes: $.map(@fields(), (x) -> x.toJSON())

  class Field
    constructor: (layer, data) ->
      @layer = layer
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @code = ko.observable data?.code
      @originalCode = @code()
      @kind = ko.observable data?.kind
      @ord = ko.observable data?.ord
      @options = if data.config?.options?
                   ko.observableArray($.map(data.config.options, (x) -> new Option(x)))
                 else
                   ko.observableArray()
      @hierarchy = ko.observable data.config?.hierarchy
      @initHierarchyItems() if @hierarchy()
      @hasFocus = ko.observable(false)
      @isOptionsKind = ko.computed => @kind() == 'select_one' || @kind() == 'select_many'
      @uploadingHierarchy = ko.observable(false)
      @fieldErrorDescription = ko.computed => if @hasName() then "'#{@name()}'" else "number #{@layer.fields().indexOf(@) + 1}"
      @nameError = ko.computed => if @hasName() then null else "the field #{@fieldErrorDescription()} is missing a Name"
      @codeError = ko.computed => if @hasCode() then null else "the field #{@fieldErrorDescription()} is missing a Code"
      @optionsError = ko.computed =>
        return null unless @isOptionsKind()

        if @options().length > 0
          codes = []
          labels = []
          for option in @options()
            return "duplicated option code '#{option.code()}' for field #{@name()}" if codes.indexOf(option.code()) >= 0
            return "duplicated option label '#{option.label()}' for field #{@name()}" if labels.indexOf(option.label()) >= 0
            codes.push option.code()
            labels.push option.label()
          null
        else
          "the field '#{@name()}' must have at least one option"
      @hierarchyError = ko.computed =>
        return null unless @kind() == 'hierarchy'
        if @hierarchy() && @hierarchy().length > 0 then null else "the field #{@fieldErrorDescription()} is missing the Hierarchy"
      @error = ko.computed => @nameError() || @codeError() || @optionsError() || @hierarchyError()
      @valid = ko.computed => !@error()

    hasName: => $.trim(@name()).length > 0

    hasCode: => $.trim(@code()).length > 0

    buttonClass: =>
      switch @kind()
        when 'text' then 'ltext'
        when 'numeric' then 'lnumber'
        when 'select_one' then 'lsingleoption'
        when 'select_many' then 'lmultipleoptions'
        when 'hierarchy' then 'lmultipleoptions'

    setHierarchy: (hierarchy) =>
      @hierarchy(hierarchy)
      @initHierarchyItems()
      @uploadingHierarchy(false)

    initHierarchyItems: =>
      @hierarchyItems = ko.observableArray $.map(@hierarchy(), (x) -> new HierarchyItem(x))

    toJSON: =>
      json =
        id: @id()
        name: @name()
        code: @code()
        kind: @kind()
        ord: @ord()
      json.config = {options: $.map(@options(), (x) -> x.toJSON())} if @isOptionsKind()
      json.config = {hierarchy: @hierarchy()} if @kind() == 'hierarchy'
      json

  class Option
    constructor: (data) ->
      @code = ko.observable(data?.code)
      @label = ko.observable(data?.label)
      @editing = ko.observable(false)
      @hasFocus = ko.observable(false)

    edit: => @editing(true)

    keyPress: (field, event) =>
      switch event.keyCode
        when 13 then @editing(false)
        else true

    toJSON: =>
      code: @code()
      label: @label()

  class HierarchyItem
    constructor: (data, level = 0) ->
      @id = ko.observable(data?.id)
      @name = ko.observable(data?.name)
      @level = ko.observable(level)
      @expanded = ko.observable(false)
      @hierarchyItems = if data.sub?
                          ko.observableArray($.map(data.sub, (x) -> new HierarchyItem(x, level + 1)))
                        else
                          ko.observableArray()

    toggleExpand: =>
      @expanded(!@expanded())

  class LayersViewModel
    constructor: (collectionId, layers) ->
      @collectionId = collectionId
      @layers = ko.observableArray $.map(layers, (x) -> new Layer(x))
      @currentLayer = ko.observable()
      @currentField = ko.observable()
      @newOption = ko.observable(new Option)
      @optionValid = ko.computed =>
        $.trim(@newOption().code()).length > 0 && $.trim(@newOption().label()).length > 0

      @currentFieldMarginTop = ko.computed =>
        if @currentLayer()
          idx = @currentLayer().fields().indexOf(@currentField())
          margin = idx * 79
          margin += 3 if idx > 0
          "#{margin}px"
        else
          0

      @savingLayer = ko.observable(false)

    newLayer: =>
      layer = new Layer ord: (@layers().length + 1)
      @layers.push(layer)
      @currentLayer(layer)
      layer.hasFocus(true)

    editLayer: (layer) =>
      @originalFields = $.map(layer.fields(), (x) -> new Field(layer, x.toJSON()))
      @currentLayer(layer)
      @currentField(layer.fields()[0]) if layer.fields().length > 0
      layer.hasFocus(true)

    cancelLayer: =>
      if @currentLayer().id()
        @currentLayer().fields.removeAll()
        @currentLayer().fields.push(field) for field in @originalFields
      else
        @layers.remove(@currentLayer()) unless @currentLayer().id()
      @currentLayer(null)
      @currentField(null)

    saveLayer: =>
      mustPrompt = false

      # Check if a field's code changed
      for field in @currentLayer().fields()
        if field.id() && field.code() != field.originalCode
          mustPrompt = true

      continueWithSaving = true
      if mustPrompt
        continueWithSaving = confirm "You renamed a field's code.\nThis can break API clients that depended on that code.\nThe renaming process will take some time to finish.\nAre you sure you want to proceed?"

      return unless continueWithSaving

      # When saving, set the originalCode field to the current field's code,
      # so when saving again the "confirm" doesn't trigger
      for field in @currentLayer().fields()
        if field.id() && field.code() != field.originalCode
          field.originalCode = field.code()

      @savingLayer(true)

      callback = (data) =>
        @currentLayer().id(data.id)

        for field, i in @currentLayer().fields()
          field.id(data.fields[i].id)

        @currentLayer(null)
        @currentField(null)

        @savingLayer(false)

      json = {layer: @currentLayer().toJSON()}

      if @currentLayer().id()
        json._method = 'put'
        $.post "/collections/#{@collectionId}/layers/#{@currentLayer().id()}.json", json, callback
      else
        $.post "/collections/#{@collectionId}/layers.json", json, callback

    saveLayerOrd: (layer) =>
      json = {ord: layer.ord()}

      json._method = 'put'
      $.post "/collections/#{@collectionId}/layers/#{layer.id()}/set_order.json", json

    deleteLayer: (layer) =>
      if confirm("Are you sure you want to delete layer #{layer.name()}?")
        $.post "/collections/#{@collectionId}/layers/#{layer.id()}", {_method: 'delete'}, =>
          idx = @layers().indexOf(layer)
          for nextLayer in @layers().slice(idx + 1)
            nextLayer.ord(nextLayer.ord() - 1)
            @saveLayerOrd(nextLayer)

          @layers.remove(layer)

    isFirstLayer: (layer) => layer.ord() == 1
    isLastLayer: (layer) => layer.ord() == @layers().length

    moveLayerDown: (layer) =>
      nextLayer = @layers()[layer.ord()]
      layer.ord(layer.ord() + 1)
      nextLayer.ord(nextLayer.ord() - 1)
      @saveLayerOrd(layer)
      @saveLayerOrd(nextLayer)
      @layers.sort((x, y) -> if x.ord() < y.ord() then -1 else 1)

    moveLayerUp: (layer) =>
      @moveLayerDown @layers()[layer.ord() - 2]

    isFirstField: (layer, field) => field.ord() == 1
    isLastField: (layer, field) => field.ord() == layer.fields().length

    moveFieldDown: (field) =>
      nextField = @currentLayer().fields()[field.ord()]
      field.ord(field.ord() + 1)
      nextField.ord(nextField.ord() - 1)
      @currentLayer().fields.sort((x, y) -> if x.ord() < y.ord() then -1 else 1)

    moveFieldUp: (field) =>
      @moveFieldDown @currentLayer().fields()[field.ord() - 2]

    newTextField: => @newField 'text'
    newNumericField: => @newField 'numeric'
    newSelectOneField: => @newField 'select_one'
    newSelectManyField: => @newField 'select_many'
    newHierarchyField: => @newField 'hierarchy'

    newField: (kind) =>
      @currentField(new Field(@currentLayer(), kind: kind, ord: @currentLayer().fields().length + 1))
      @currentLayer().fields.push(@currentField())
      @currentField().hasFocus(true)

    selectField: (field) =>
      @currentField(field)
      @currentField().hasFocus(true)

    deleteField: (field) =>
      idx = @currentLayer().fields().indexOf(field)
      nextField.ord(nextField.ord() - 1) for nextField in @currentLayer().fields().slice(idx + 1)
      @currentLayer().fields.remove(field)
      if @currentLayer().fields().length == 0
        @currentField(null)
      else
        idx -= 1 if idx >= @currentLayer().fields().length
        @currentField(@currentLayer().fields()[idx])
        @currentField().hasFocus(true)

    newOptionKeyPress: (field, event) =>
      switch event.keyCode
        when 13 then @addOption()
        else true

    optionBlur: (option) =>
      option.editing(false)
      if $.trim(option.code()).length == 0 && $.trim(option.length()).length == 0
        @removeOption(option)

    addOption: =>
      return unless @optionValid()
      @newOption().hasFocus = false
      @currentField().options.push(@newOption())
      option = new Option
      option.hasFocus(true)
      @newOption(option)

    removeOption: (option) =>
      @currentField().options.remove(option)
      @newOption().hasFocus(true)

    startUploadHierarchy: =>
      @currentField().uploadingHierarchy(true)

    hierarchyUploaded: (hierarchy) =>
      @currentField().setHierarchy(hierarchy)

  match = window.location.toString().match(/\/collections\/(\d+)\/layers/)
  collectionId = parseInt(match[1])

  $.get "/collections/#{collectionId}/layers.json", {}, (layers) =>
    window.model = new LayersViewModel(collectionId, layers)
    ko.applyBindings window.model
