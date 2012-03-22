@initMemberships = (userId, collectionId, layers) ->
  window.userId = userId

  class Layer
    constructor: (data) ->
      @id = data?.id
      @name = data?.name

  class LayerMembership
    constructor: (data) ->
      @layerId = ko.observable data.layer_id
      @read = ko.observable data.read
      @write = ko.observable data.write

  class Membership
    constructor: (data) ->
      @userId = ko.observable data?.user_id
      @userDisplayName = ko.observable data?.user_display_name
      @admin = ko.observable data?.admin
      @layers = ko.observableArray $.map(data?.layers ? [], (x) -> new LayerMembership(x))

      @adminUI = ko.computed => if @admin() then "<b>Yes</b>" else "No"
      @isCurrentUser = ko.computed => window.userId == @userId()

      @layer = ko.computed =>
        selectedLayerId = window.model.selectedLayer()?.id ? null
        layer = @layers().filter((x) -> x.layerId() == selectedLayerId)
        if layer.length > 0 then layer[0] else null

      @canRead = ko.computed
        read: => if @admin() then true else @layer()?.read()
        write: (value) =>
          layer_id = window.model.selectedLayer()?.id
          $.post "/collections/#{collectionId}/memberships/#{@userId()}/set_layer_access.json", {layer_id: layer_id, verb: 'read', access: value}, =>
            if @layer()
              @layer().read value
            else
              @layers().push new LayerMembership(layer_id: layer_id, read: value, write: false)
        owner: @

      @canWrite = ko.computed
        read: => if @admin() then true else @layer()?.write()
        write: (value) =>
          layer_id = window.model.selectedLayer()?.id
          $.post "/collections/#{collectionId}/memberships/#{@userId()}/set_layer_access.json", {layer_id: layer_id, verb: 'write', access: value}, =>
            if @layer()
              @layer().write value
            else
              @layers().push new LayerMembership(layer_id: layer_id, read: false, write: value)
        owner: @

  class MembershipsViewModel
    initialize: (memberships, layers) ->
      @selectedLayer = ko.observable()
      @memberships = ko.observableArray $.map(memberships, (x) -> new Membership(x))
      @layers = ko.observableArray $.map(layers, (x) -> new Layer(x))

    destroyMembership: (membership) =>
      if confirm("Are you sure you want to remove #{membership.userDisplayName()} from the collection?")
        $.post "/collections/#{collectionId}/memberships/#{membership.userId()}.json", {_method: 'delete'}, =>
          @memberships.remove membership

  $.get "/collections/#{collectionId}/memberships.json", (memberships) ->
    window.model = new MembershipsViewModel
    window.model.initialize memberships, layers
    ko.applyBindings window.model

    $member_email = $('#member_email')

    createMembership = (email = $member_email.val()) ->
      if $.trim(email).length > 0
        $.post "/collections/#{collectionId}/memberships.json", {email: email}, (data) ->
          if data.status == 'added'
            window.model.memberships.push new Membership(user_id: data.user_id, user_display_name: data.user_display_name)
            $member_email.val('')

    $member_email.autocomplete
      source: "/collections/#{collectionId}/memberships/invitable.json"
      select: (event, ui) -> createMembership(ui.item.label)

    $member_email.keydown (event) ->
      if event.keyCode == 13
        createMembership()

    $('#add_member').click -> createMembership()
