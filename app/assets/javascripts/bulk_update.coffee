@initBulkUpdate = (collectionId, columns) ->
  class Property
    constructor: (data) ->
      @code = ko.observable data.code
      @name = ko.observable data.name
      @kind = ko.observable data.kind
      @value = ko.observable data.value
      @valueCode = ko.observable data.valueCode
      @valueLabel = ko.observable data.valueLabel

  class Site
    constructor: (data) ->
      @name = ko.observable data.name
      @lat = ko.observable data.lat
      @lng = ko.observable data.lng
      @properties = ko.observable data.properties
      @hasMoreThanOneName = ko.observable data.hasMoreThanOneName

      @error = ko.computed =>
        return "you must choose a column to be the Name of the site" unless @name()
        return "you chose more than one column to be the Name of the site" if @hasMoreThanOneName()

        for property in @properties()
          if property.kind() == 'select_one' || property.kind() == 'select_many'
            return "you must choose a column to be the Code of property #{property.code()}" unless property.valueCode()
            return "you must choose a column to be the Label of property #{property.code()}" unless property.valueLabel()
        null

      @valid = ko.computed => !@error()

  class Column
    constructor: (data) ->
      @name = ko.observable data.name
      @kind = ko.observable data.kind
      @code = ko.observable data.code
      @label = ko.observable data.label
      @sample = ko.observable data.sample
      @value = ko.observable data.value
      @level = ko.observable 1
      @selectKind = ko.observable 'code'

      @mapsToField = ko.computed =>
        @kind() == 'text' || @kind() == 'numeric' || @kind() == 'select_one' || @kind() == 'select_many'

    toJSON: =>
      json =
        name: @name()
        kind: @kind()
      if @mapsToField()
        json.code = @code()
        json.label = @label()
      json.selectKind = @selectKind() if @kind() == 'select_one' || @kind() == 'select_many'
      json

  class BulkUpdateViewModel
    constructor: (collectionId, columns) ->
      @collectionId = collectionId
      @columns = ko.observableArray $.map(columns, (x) -> new Column(x))
      @site = ko.computed => @computeSite()
      @error = ko.computed => @site().error()
      @valid = ko.computed => @site().valid()
      @importing = ko.observable false
      @importError = ko.observable false

    computeSite: =>
      data = {name: null, properties: []}
      propertiesByCode = {}
      levels = {}

      for column in @columns()
        if column.kind() == 'name'
          if data.name
            data.hasMoreThanOneName = true
          data.name = column.value()
          continue

        if column.kind() == 'lat'
          data.lat = column.value()
          continue

        if column.kind() == 'lng'
          data.lng = column.value()
          continue

        continue unless column.mapsToField()

        existing = null
        propertyData = code: column.code(), name: column.label(), kind: column.kind(), value: column.value()

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

        unless existing
          property = new Property(propertyData)
          data.properties.push property

        if !existing && (column.kind() == 'select_one' || column.kind() == 'select_many')
          propertiesByCode[column.code()] = property

      new Site data

    startImport: =>
      @importing(true)
      columns = $.map(@columns(), (x) -> x.toJSON())
      $.ajax "/collections/#{@collectionId}/bulk_update_execute.json",
        type: 'POST'
        data: {columns: columns},
        success: => window.location = '/collections'
        error: =>
          @importing(false)
          @importError(true)

  window.model = new BulkUpdateViewModel(collectionId, columns)
  ko.applyBindings window.model
