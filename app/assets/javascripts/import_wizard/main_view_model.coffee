onImportWizard ->
  class @Usage
    constructor: (@name, @code) ->

  class @MainViewModel
    initialize: (collectionId, layers, columns) ->
      @collectionId = collectionId
      @layers = $.map(layers, (x) -> new Layer(x))
      @columns = ko.observableArray $.map(columns, (x) -> new Column(x))

      @usages = [new Usage('New field', 'new_field')]
      if @layers.length > 0
        @usages.push(new Usage('Existing field', 'existing_field'))
        @usages.push(new Usage('ID', 'id'))
      @usages.push(new Usage('Name', 'name'))
      @usages.push(new Usage('Latitude', 'lat'))
      @usages.push(new Usage('Longitude', 'lng'))
      @usages.push(new Usage('Ignore', 'ignore'))

      @site = ko.computed => @computeSite()
      @error = ko.computed => @site().error()
      @valid = ko.computed => @site().valid()
      @importing = ko.observable false
      @importError = ko.observable false

    findLayer: (id) =>
      (layer for layer in @layers when layer.id == id)[0]

    computeSite: =>
      data = {name: null, properties: []}
      propertiesByCode = {}
      propertiesByField = {}
      levels = {}

      for column in @columns()
        if column.usage() == 'ignore'
          continue

        if column.usage() == 'id'
          if data.id
            data.hasMoreThanOneId = true
          data.id = column.value()
          continue

        if column.usage() == 'name'
          if data.name
            data.hasMoreThanOneName = true
          data.name = column.value()
          continue

        if column.usage() == 'lat'
          if data.lat
            data.hasMoreThanOneLat = true
          data.lat = column.value()
          continue

        if column.usage() == 'lng'
          if data.lng
            data.hasMoreThanOneLng = true
          data.lng = column.value()
          continue

        existing = null
        propertyData =
          usage: column.usage()
          column: column.name()
          layer: column.layer()
          field: column.field()
          kind: column.kind()
          code: column.code()
          name: column.label()
          value: column.value()

        if column.usage() == 'new_field'
          if column.kind() == 'select_one' || column.kind() == 'select_many'
            existing = propertiesByCode[column.code()]
            if existing
              switch column.selectKind()
                when 'code'
                  existing.valueCode column.value()
                when 'label'
                  existing.valueLabel column.value()
                when 'both'
                  existing.valueCode column.value()
                  existing.valueLabel column.value()
            else
              switch column.selectKind()
                when 'code'
                  propertyData.valueCode = column.value()
                when 'label'
                  propertyData.valueLabel = column.value()
                when 'both'
                  propertyData.valueCode = column.value()
                  propertyData.valueLabel = column.value()
        else
          if propertiesByField[column.field().id]
            data.hasMoreThanOneField = "#{column.layer().name} - #{column.field().name}"
          propertiesByField[column.field().id] = true

        unless existing
          property = new Property(propertyData)
          data.properties.push property

        if !existing && (column.kind() == 'select_one' || column.kind() == 'select_many')
          propertiesByCode[column.code()] = property

      new Site data

    startImport: =>
      @importing(true)
      columns = $.map(@columns(), (x) -> x.toJSON())
      $.ajax "/collections/#{@collectionId}/import_wizard_execute.json",
        type: 'POST'
        data: {columns: columns},
        success: => window.location = '/collections'
        error: =>
          @importing(false)
          @importError(true)
