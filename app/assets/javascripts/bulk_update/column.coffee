onBulkUpdate ->
  class @Column
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
