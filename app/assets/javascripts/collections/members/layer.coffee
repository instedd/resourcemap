class @Layer
  constructor: (data) ->
    @id = ko.observable data?.id
    @name = ko.observable data?.name
