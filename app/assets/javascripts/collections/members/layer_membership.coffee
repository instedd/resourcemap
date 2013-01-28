class @LayerMembership
  constructor: (layer, layer_memberships, membership) ->
    _self = @

    layer_membership = _.find layer_memberships, (l) -> l.layer_id == layer.id()

    @layerName = ko.observable layer.name
    @layerId = ko.observable layer.id

    if layer_membership?
      @read = ko.observable layer_membership.read
      @write = ko.observable layer_membership.write
    else
      # If there isn't a LayerMembership object corresponding to the given layer, all permissions are denied.
      @read = ko.observable false
      @write = ko.observable false

    @noneChecked = ko.computed
      read: =>
        if not _self.write() and not _self.read()
          "true"
        else
          ""
      write: (val) =>
        _self.write false
        _self.read false

    @readChecked = ko.computed
      read: =>
        if _self.read() and not _self.write()
          "true"
        else
          ""
      write: (val) =>
        _self.write false
        _self.read true


    @updateChecked = ko.computed
      read: =>
        if _self.write()
          "true"
        else
          ""
      write: (val) =>
        _self.write true
        _self.read true

