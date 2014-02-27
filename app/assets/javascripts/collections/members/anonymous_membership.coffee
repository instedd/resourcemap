#= require collections/members/membership

class @AnonymousMembership extends Membership
  constructor: (root, data) ->
    super
    _self = @
    @showAdminCheckbox = false
    @userDisplayName = "Anonymous users"
    @isAnonymous = true
    @defaultRead(true)
    @defaultWrite(true)
    @namePermission("read")
    @locationPermission("read")
    @set_layer_access_path = ko.computed => "/collections/#{@collectionId()}/memberships/set_layer_access_anonymous_user.json"


