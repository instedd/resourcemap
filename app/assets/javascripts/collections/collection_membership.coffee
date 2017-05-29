#= require collections/sites_permission
onCollections ->

  class @CollectionMembership
    @constructorCollectionMembership: ->
      @membershipInitialized = false
      @anyUpdatePermissions = ko.observable(false)

    @fetchMembership: (callback)->
      if @membershipInitialized
        callback() if typeof(callback) is 'function'
        return

      loaded = false

      # TODO: Remove this and load it form curren_user_membership
      $.get "/collections/#{@id}/sites_permission", {}, (data) =>
        @sitesPermission = new SitesPermission(data)
        if loaded
          @membershipInitialized = true
          callback() if typeof(callback) is 'function'
        else
          loaded = true


      $.get "/collections/#{@id}/current_user_membership.json", {}, (membership) =>
        @namePermission = membership.name
        @locationPermission = membership.location
        @anyUpdatePermissions(@namePermission == "update" && @locationPermission == "update")
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
