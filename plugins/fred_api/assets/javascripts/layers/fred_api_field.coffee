onLayers ->
  class @Field_identifier extends @FieldImpl
    constructor: (field) ->
      super(field)

      @context = ko.observable field.config?.context
      @agency = ko.observable field.config?.agency

      @contextError = ko.computed =>
        if $.trim(@context()).length > 0
          null
        else
          "the field #{field.fieldErrorDescription()} is missing a Context"

      @agencyError = ko.computed =>
        if $.trim(@agency()).length > 0
          null
        else
          "the field #{field.fieldErrorDescription()} is missing an Agency"

      @error = ko.computed => @contextError() || @agencyError()

    toJSON: (json) =>
      json.config =
        context: @context()
        agency: @agency()
