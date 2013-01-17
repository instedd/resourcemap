class @LayerMembership
  constructor: (data) ->
    @layerId = ko.observable data.layer_id
    @read = ko.observable data.read
    @write = ko.observable data.write
