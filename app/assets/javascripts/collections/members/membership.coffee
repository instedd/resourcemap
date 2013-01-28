#= require collections/members/membership_layout

class @Membership extends Expandable
  @include MembershipLayout

  constructor: (root, data) ->
    _self = @

    # Defined this before callModuleConstructors because it's used by MembershipLayout
    @userId = ko.observable data?.user_id
    @userDisplayName = ko.observable data?.user_display_name
    @admin = ko.observable data?.admin

    rootLayers = data?.layers ? []
    @layers = ko.observableArray $.map(root.layers(), (x) => new LayerMembership(x, rootLayers))

    @sitesWithCustomPermissions = ko.observableArray SiteCustomPermission.arrayFromJson(data?.sites)

    @callModuleConstructors(arguments)
    super

    all = (permitted) ->
      _.all _self.layers(), (l) => permitted l

    some = (permitted) ->
      (_.some _self.layers(), (l) => permitted l) and not all permitted

    none = (permitted) ->
      not _.any _self.layers(), (l) => permitted l

    summarize = (permitted) ->
      return 'All' if all permitted
      return 'Some' if some permitted
      return '' if none permitted

    nonePermission = (l) => not @admin() and not l.read() and not l.write()
    readPermission = (l) => not @admin() and l.read() and not l.write()
    writePermission = (l) => @admin() or l.write()

    @adminUI = ko.computed => if @admin() then "<b>Yes</b>" else "No"
    @isCurrentUser = ko.computed => window.userId == @userId()

    @admin.subscribe (newValue) =>
      $.post "/collections/#{root.collectionId()}/memberships/#{@userId()}/#{if newValue then 'set' else 'unset'}_admin.json"

    @someLayersNone = ko.computed => some nonePermission

    @allLayersNone = ko.computed => all nonePermission
    @allLayersRead = ko.computed => all readPermission
    @allLayersUpdate = ko.computed
      read: =>
        return 'all' if all writePermission
        ''
      write: (val) =>
        _self = @
        _.each @layers(), (layer) ->
          $.post "/collections/#{root.collectionId()}/memberships/#{_self.userId()}/set_layer_access.json", { layer_id: layer.layerId(), verb: 'write', access: val}, =>
            layer.write(val)

    @isNotAdmin = ko.computed => not @admin()

    @summaryNone = ko.computed => summarize nonePermission
    @summaryRead = ko.computed => summarize readPermission
    @summaryUpdate = ko.computed => summarize writePermission
    @summaryAdmin = ko.computed => ''


  initializeLinks: =>
    @membershipLayerLinks = ko.observableArray $.map(window.model.layers(), (x) => new MembershipLayerLink(@, x))
    @initializeAllReadAllWrite()

  findLayerMembership: (layer) =>
    lm = @layers().filter((x) -> x.layerId() == layer.id())
    if lm.length > 0 then lm[0] else null
