#= require collections/members/membership

class @AnonymousMembership extends Membership
  constructor: (root, data) ->
    super
    _self = @
    @showAdminCheckbox = false
    @userDisplayName = __("Anonymous users")
    @isAnonymous = true
    @set_layer_access_path = ko.computed => "/collections/#{@collectionId()}/memberships/set_layer_access_anonymous_user.json"
    @set_access_path = ko.computed => "/collections/#{@collectionId()}/memberships/set_access_anonymous_user.json"
    @allNoneNameLocationPerm('none')

    @setNameLocation = (access) =>
      if (@namePermission() != access)
        @namePermission(access)
        $.post @set_access_path(), { object: 'name', new_action: access}
      if (@locationPermission() != access)
        @locationPermission(access)
        $.post @set_access_path(), { object: 'location', new_action: access}

    @writeNamePermission = @setNameLocation
    @writeLocationPermission = @setNameLocation
