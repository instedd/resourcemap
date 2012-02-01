@initLayers = (initialLayers) ->
  class Layer
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @public = ko.observable data?.public
      if data?.fields
        @fields = ko.observableArray($.map(data.fields, (x) -> new Field(x)))
      else
        @fields = ko.observableArray([])
      @hasFocus = ko.observable(false)

    toJSON: =>
      id: @id()
      name: @name()
      public: @public()
      fields_attributes: $.map(@fields(), (x) -> x.toJSON())

  class Field
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @code = ko.observable data?.code
      @kind = ko.observable data?.kind
      @hasFocus = ko.observable(false)

    buttonClass: =>
      switch @kind()
        when 'text' then 'ltext'
        when 'number' then 'lnumber'

    toJSON: =>
      name: @name()
      code: @code()
      kind: @kind()

  class LayersViewModel
    constructor: ->
      @layers = ko.observableArray $.map(initialLayers, (x) -> new Layer(x))
      @currentLayer = ko.observable()
      @currentField = ko.observable()

    newLayer: =>
      layer = new Layer
      @layers.push(layer)
      @currentLayer(layer)
      layer.hasFocus(true)

    editLayer: (layer) =>
      @originalFields = $.map(layer.fields(), (x) -> x)
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
      callback = (data) =>
        @currentLayer().id(data.id)
        @currentLayer(null)

      json = {layer: @currentLayer().toJSON()}

      if @currentLayer().id()
        json._method = 'put'
        $.post "/collections/#{collectionId}/layers/#{@currentLayer().id()}.json", json, callback
      else
        $.post "/collections/#{collectionId}/layers.json", json, callback

    deleteLayer: (layer) =>
      if confirm("Are you sure you want to delete layer #{layer.name()}?")
        $.post "/collections/#{collectionId}/layers/#{layer.id()}", {_method: 'delete'}, =>
          @layers.remove(layer)

    newTextField: =>
      @currentField(new Field(kind: 'text'))
      @currentLayer().fields.push(@currentField())
      @currentField().hasFocus(true)

    newNumberField: =>
      @currentField(new Field(kind: 'number'))
      @currentLayer().fields.push(@currentField())
      @currentField().hasFocus(true)

    selectField: (field) =>
      @currentField(field)
      @currentField().hasFocus(true)

    deleteField: (field) =>
      @currentLayer().fields.remove(field)
      if @currentField() == field
        if @currentLayer().fields().length == 0
          @currentField(null)
        else
          @currentField(@currentLayer().fields()[0])
          @currentField().hasFocus(true)


  ko.applyBindings new LayersViewModel
