#= require collections/sites_permission
onCollections ->

  class @CollectionMembership
    @constructorCollectionMembership: (@collectionsApi = Resmap.Api.Collections) ->
      @membershipInitialized = false
      @anyUpdatePermissions = ko.observable(false)

    @fetchMembership: (callback)->
      if @membershipInitialized
        callback() if typeof(callback) is 'function'
        return

      loaded = false

      # TODO: Remove this and load it form curren_user_membership
      @collectionsApi.getSitesPermission(@id).then (data) =>
        @sitesPermission = new SitesPermission(data)
        if loaded
          @membershipInitialized = true
          callback() if typeof(callback) is 'function'
        else
          loaded = true

      @collectionsApi.getCurrentUserMembership(@id).then (membership) =>
        @namePermission = membership.name
        @locationPermission = membership.location
        nameOrLocation = @namePermission == "update" || @locationPermission == "update"
        @anyUpdatePermissions nameOrLocation || $.grep(membership.layers, (l) ->
          l.write).length > 0
        if loaded
          @membershipInitialized = true
          callback() if typeof(callback) is 'function'
        else
          loaded = true


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
