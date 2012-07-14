onLayers ->
  class @MainViewModel
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
      @savingLayer(true)

      json = {layer: @currentLayer().toJSON()}

      if @currentLayer().id()
        json._method = 'put'
        $.post "/collections/#{@collectionId}/layers/#{@currentLayer().id()}.json", json, @saveLayerCallback
      else
        $.post "/collections/#{@collectionId}/layers.json", json, @saveLayerCallback

    saveLayerCallback: (data) =>
      @currentLayer().id(data.id)

      for field, i in @currentLayer().fields()
        field.id(data.fields[i].id)

      @currentLayer(null)
      @currentField(null)

      @savingLayer(false)

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
    newUserField: => @newField 'user'
    newEmailField: => @newField 'email'

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
      @currentField().addOption(@newOption())
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
