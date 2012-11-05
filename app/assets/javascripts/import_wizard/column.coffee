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

    iconClass: =>
        if @field()
            FIELD_TYPES[@kind()].small_css_class || 'faccept'
        else
            'faccept'

