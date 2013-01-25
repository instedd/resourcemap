class @LayerMembership
  constructor: (layer, layer_memberships) ->
    layer_membership = _.find layer_memberships, (l) -> l.layer_id == layer.id()

    @layerId = ko.observable layer.id

    if layer_membership?
      @read = ko.observable layer_membership.read
      @write = ko.observable layer_membership.write
    else
      # If there isn't a LayerMembership object corresponding to the given layer, all permissions are denied.
      @read = ko.observable false
      @write = ko.observable false

