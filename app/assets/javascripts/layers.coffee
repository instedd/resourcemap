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

    enterCreateLayer: =>
      @currentLayer(new Layer)

    enterCreateTextField: =>
      @currentField(new Field(kind: 'text'))
      @currentLayer().fields.push(@currentField())

    enterCreateNumberField: =>
      @currentField(new Field(kind: 'number'))
      @currentLayer().fields.push(@currentField())

    selectField: (field) =>
      @currentField(field)

    saveLayer: =>
      $.post "/collections/#{collectionId}/layers.json", {layer: @currentLayer().toJSON()}, (data) =>
        alert data


  ko.applyBindings new LayersViewModel
