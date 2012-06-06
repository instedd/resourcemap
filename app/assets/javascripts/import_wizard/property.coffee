onImportWizard ->
  class @Property
    constructor: (data) ->
      @column = data.column
      @usage = data.usage
      @layer = data.layer
      @field = data.field
      @kind = data.kind
      @code = data.code
      @name = data.name
      @value = data.value
      @valueCode = data.valueCode
      @valueLabel = data.valueLabel
