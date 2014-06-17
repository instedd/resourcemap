onLayers ->
  class @Layer
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @public = ko.observable data?.public
      @ord = ko.observable data?.ord
      if data?.fields
        @fields = ko.observableArray($.map(data.fields, (x) => new Field(@, x)))
      else
        @fields = ko.observableArray([])
      @hasFocus = ko.observable(false)
      @nameError = ko.computed => if @hasName() then null else __("the layer's Name is missing")
      @fieldsError = ko.computed =>
        return __("the layer must have at least one field") if @fields().length == 0

        codes = []
        names = []

        # Check that the name and code are not duplicated
        for field in @fields()
          field_error = field.error()

          return field_error if field_error
          return Jed.sprintf(__("duplicated field name '%s'"), field.name()) if names.indexOf(field.name()) >= 0
          return Jed.sprintf(__("duplicated field code '%s'"), field.code()) if codes.indexOf(field.code()) >= 0
          names.push field.name()
          codes.push field.code()

        # Now check that the names and codes don't apper in other layers
        if window.model
          for layer in window.model.layers() when layer != @
            for field in layer.fields()
              return Jed.sprintf(__("a field with name '%s' already exists in the layer named %s"), field.name(), layer.name()) if names.indexOf(field.name()) >= 0
              return Jed.sprintf(__("a field with code '%s' already exists in the layer named %s"), field.code(), layer.name()) if codes.indexOf(field.code()) >= 0

        null
      @error = ko.computed => @nameError() || @fieldsError()
      @valid = ko.computed => !@error()

    hasName: => $.trim(@name()).length > 0

    toJSON: =>
      id: @id()
      name: @name()
      ord: @ord()
      fields_attributes: $.map(@fields(), (x) -> x.toJSON())
