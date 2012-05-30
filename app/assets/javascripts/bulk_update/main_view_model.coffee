onBulkUpdate ->
  class @MainViewModel
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
