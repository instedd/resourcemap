#= require collections/members/membership_layout

class @Membership extends Expandable
  @include AdvancedMembershipMode
  @include MembershipLayout

  constructor: (root, data) ->
    # Defined this before callModuleConstructors because it's used by MembershipLayout
    @sitesWithCustomPermissions = ko.observableArray SiteCustomPermission.arrayFromJson(data?.sites)

    @callModuleConstructors(arguments)
    super

    @userId = ko.observable data?.user_id
    @userDisplayName = ko.observable data?.user_display_name
    @admin = ko.observable data?.admin
    @layers = ko.observableArray $.map(data?.layers ? [], (x) => new LayerMembership(x))

    @adminUI = ko.computed => if @admin() then "<b>Yes</b>" else "No"
    @isCurrentUser = ko.computed => window.userId == @userId()

    @admin.subscribe (newValue) =>
      $.post "/collections/#{collectionId}/memberships/#{@userId()}/#{if newValue then 'set' else 'unset'}_admin.json"

    @someLayersNone = ko.computed => _.some @layers(), (l) => not l.read() and not l.write()

    @isNotAdmin = ko.computed => not @admin()

    @summaryNone = ko.computed => 'All'
    @summaryRead = ko.computed => 'Some'
    @summaryUpdate = ko.computed => 'All'
    @summaryAdmin = ko.computed => ''

  initializeLinks: =>
    @membershipLayerLinks = ko.observableArray $.map(window.model.layers(), (x) => new MembershipLayerLink(@, x))
    @initializeAllReadAllWrite()

  findLayerMembership: (layer) =>
    lm = @layers().filter((x) -> x.layerId() == layer.id())
    if lm.length > 0 then lm[0] else null
