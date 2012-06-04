onBulkUpdate ->
  class @Property
    constructor: (data) ->
      @code = ko.observable data.code
      @name = ko.observable data.name
      @kind = ko.observable data.kind
      @value = ko.observable data.value
      @valueCode = ko.observable data.valueCode
      @valueLabel = ko.observable data.valueLabel
