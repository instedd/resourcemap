#= require collections/sites_permission
onCollections ->

  class @CollectionMembership
    @constructorCollectionMembership: ->
      @membershipInitialized = false
      @anyUpdatePermissions = false

    @fetchMembership: (callback)->
      if @membershipInitialized
        callback() if typeof(callback) is 'function'
        return

      # TODO: Remove this and load it form curren_user_membership
      $.get "/collections/#{@id}/sites_permission", {}, (data) =>
        @sitesPermission = new SitesPermission(data)

      $.get "/collections/#{@id}/current_user_membership.json", {}, (membership) =>
        @namePermission = membership.name
        @locationPermission = membership.location
        debugger
        nameOrLocation = @namePermission == "update" || @locationPermission == "update"
        @anyUpdatePermissions = nameOrLocation || $.grep(membership.layers, (l) ->
          l.write).length > 0

      @membershipInitialized = true
      callback() if typeof(callback) is 'function'

    @readable: (site) ->
      @sitesPermission.canRead(site)

    @canDeleteSites: ->
      @sitesPermission.canDeleteSites()

    @updatePermission: (site, callback) ->
      @fetchMembership =>
        canUpdate = @sitesPermission.canUpdate(site)
        field.writeable = (canUpdate and field.writeable) for field in @fields()
        site.nameWriteable = (canUpdate and @namePermission == 'update')
        site.locationWriteable = (canUpdate and @locationPermission == 'update')
        callback() if typeof(callback) is 'function'
