@initLayers = (initialLayers) ->
  class Layer
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @public = ko.observable data?.public
      @fields = ko.observableArray([])

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

    buttonClass: =>
      switch @kind()
        when 'text' then 'ltext'
        when 'number' then 'lnumber'

    toJSON: =>
      id: @id()
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

    cancelLayer: =>
      @layers.remove(@currentLayer()) unless @currentLayer().id()
      @currentLayer(null)

    editLayer: (layer) =>
      @currentLayer(layer)

    saveLayer: =>
      $.post "/collections/#{collectionId}/layers.json", {layer: @currentLayer().toJSON()}, (data) =>
        @currentLayer().id(data.id)
        @layers.push(@currentLayer())
        @currentLayer(null)

    newTextField: =>
      @currentField(new Field(kind: 'text'))
      @currentLayer().fields.push(@currentField())

    newNumberField: =>
      @currentField(new Field(kind: 'number'))
      @currentLayer().fields.push(@currentField())

    selectField: (field) =>
      @currentField(field)

    deleteField: (field) =>
      @currentLayer().fields.remove(field)
      if @currentField() == field
        if @currentLayer().fields().length == 0
          @currentField(null)
        else
          @currentField(@currentLayer().fields()[0])


  ko.applyBindings new LayersViewModel
