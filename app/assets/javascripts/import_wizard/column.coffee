onImportWizard ->
  class @Column
    constructor: (data) ->
      @name = ko.observable data.name

      # How to use this column (new field? existing field? id? name? lat? lng? ignore?)
      @usage = ko.observable data.usage

      # For existing fields
      @layer = ko.observable(if data.layer_id then window.model.findLayer(data.layer_id) else null)
      @field = ko.observable(if @layer() then @layer().findField(data.field_id) else null)

      # For new fields
      @kind = ko.observable data.kind
      @code = ko.observable data.code
      @label = ko.observable data.label

      # For new select_one or select_many fields
      @selectKind = ko.observable 'code'

      @value = ko.observable data.value

      @iconClass = ko.computed => @computeIconClass()

      @kind.subscribe =>
        window.model.validateSites()

      @field.subscribe =>
        window.model.validateSites()

    toJSON: =>
      json =
        usage: @usage()
        name: @name()
      if @usage() == 'existing_field'
        json.field_id = @field().id
      if @usage() == 'new_field'
        json.kind = @kind()
        json.code = @code()
        json.label = @label()
        json.selectKind = @selectKind() if @kind() == 'select_one' || @kind() == 'select_many'
      json

    computeIconClass: =>
      if @usage() == 'existing_field'
        kind = @field().kind
      else
        kind = @kind()

      console.log(kind)

      field_class = FIELD_TYPES[kind]

      if field_class
        field_class.small_css_class
      else
        'faccept'



