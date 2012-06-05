onImportWizard ->
  class @Site
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
