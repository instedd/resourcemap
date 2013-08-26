#= require collections/sites_permission
onCollections ->

  class @Membership
    @constructorMembership: ->
      @membershipInitialized = false

    @fetchMembership: (callback)->
      if @membershipInitialized
        callback() if typeof(callback) is 'function'
        return

      # TODO: Remove this and load it form curren_user_membership
      $.get "/collections/#{@id}/sites_permission", {}, (data) =>
        @sitesPermission = new SitesPermission(data)

      $.get "/collections/#{@id}/current_user_membership.json", {}, (membership) ->
        @namePermission = membership.name
        @locationPermission = membership.location

      @membershipInitialized = true
      callback() if typeof(callback) is 'function'

    @readable: (site) ->
      @sitesPermission.canRead(site)

    @updatePermission: (site, callback) ->
      @fetchMembership =>
        canUpdate = @sitesPermission.canUpdate(site)
        field.writeable = (canUpdate and field.writeable) for field in @fields()
        site.nameWriteable = (canUpdate and @namePermission == 'update')
        site.locationWriteable = (canUpdate and @locationPermission == 'update')
        debugger
        callback() if typeof(callback) is 'function'
