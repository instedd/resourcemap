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

