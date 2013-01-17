class @MembershipLayerLink
  constructor: (membership, layer) ->
    @membership = membership
    @layer = layer

    @canRead = ko.computed
      read: =>
        if @membership.admin()
          true
        else
          @membership.findLayerMembership(@layer)?.read()
      write: (value) =>
        return if @membership.admin() || value == @canRead()

        @canWrite false if !value

        $.post "/collections/#{collectionId}/memberships/#{@membership.userId()}/set_layer_access.json", {layer_id: @layer.id(), verb: 'read', access: value}, =>
          lm = @membership.findLayerMembership(@layer)
          if lm
            lm.read value
          else
            @membership.layers.push new LayerMembership(layer_id: @layer.id(), read: value, write: false)
      owner: @

    @canWrite = ko.computed
      read: =>
        if @membership.admin()
          true
        else
          @membership.findLayerMembership(@layer)?.write()
      write: (value) =>
        return if @membership.admin() || value == @canWrite()

        @canRead true if value

        $.post "/collections/#{collectionId}/memberships/#{@membership.userId()}/set_layer_access.json", {layer_id: @layer.id(), verb: 'write', access: value}, =>
          lm = @membership.findLayerMembership(@layer)
          if lm
            lm.write value
          else
            @membership.layers.push new LayerMembership(layer_id: @layer.id(), read: value, write: value)
      owner: @

    @canReadUI = ko.computed => if @canRead() then "Yes" else "No"
    @canWriteUI = ko.computed => if @canWrite() then "Yes" else "No"
