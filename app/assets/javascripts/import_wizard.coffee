@initImportWizard = (columns) ->
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
      @parents = ko.observable data.parents

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

  class ImportWizardViewModel
    constructor: (columns) ->
      @columns = ko.observableArray $.map(columns, (x) -> new Column(x))
      @site = ko.computed =>
        data = {name: null, properties: [], parents: []}
        propertiesByCode = {}

        for column in @columns()
          if column.kind() == 'name'
            data.name = column.value()
            continue

          if column.kind() == 'lat'
            data.lat = column.value()
            continue

          if column.kind() == 'lng'
            data.lng = column.value()
            continue

          if column.kind() == 'group'
            data.parents.push {name: column.value(), level: column.level()}
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

        data.parents.sort (x, y) -> if x.level < y.level then -1 else (if x.level > y.level then 1 else 0)
        data.parents = $.map(data.parents, (x) -> x.name)

        new Site data

  ko.applyBindings new ImportWizardViewModel(columns)
