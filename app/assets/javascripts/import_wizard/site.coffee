onImportWizard ->
  class @Site
    constructor: (data) ->
      @id = ko.observable data.id
      @name = ko.observable data.name
      @lat = ko.observable data.lat
      @lng = ko.observable data.lng
      @properties = ko.observable data.properties
      @hasMoreThanOneId = ko.observable data.hasMoreThanOneId
      @hasMoreThanOneName = ko.observable data.hasMoreThanOneName
      @hasMoreThanOneLat = ko.observable data.hasMoreThanOneLat
      @hasMoreThanOneLng = ko.observable data.hasMoreThanOneLng
      @hasMoreThanOneField = ko.observable data.hasMoreThanOneField

      @error = ko.computed =>
        return "you must choose a column to be the Name of the site" unless @name()
        return "you chose more than one column to be the ID of the site" if @hasMoreThanOneId()
        return "you chose more than one column to be the Name of the site" if @hasMoreThanOneName()
        return "you chose more than one column to be the Latitude of the site" if @hasMoreThanOneLat()
        return "you chose more than one column to be the Longitude of the site" if @hasMoreThanOneLng()
        return "you chose more than one column to be the existing '#{@hasMoreThanOneField()}' field" if @hasMoreThanOneField()

        for property in @properties()
          if property.kind == 'select_one' || property.kind == 'select_many'
            return "you must choose a column to be the Code of property #{property.code}" unless property.valueCode
            return "you must choose a column to be the Label of property #{property.code}" unless property.valueLabels

        null

      @valid = ko.computed => !@error() && !window.model.validationErrors()
