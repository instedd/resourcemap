#= require collections/sites_permission
onCollections ->

  class @SitesMembership
    @constructorSitesMembership: ->
      @siteMembershipInitialized = false

    @fetchSitesMembership: (callback)->
      if @siteMembershipInitialized
        callback() if typeof(callback) is 'function'
        return

      @siteMembershipInitialized = true
      $.get "/collections/#{@id}/sites_permission", {}, (data) =>
        @sitesPermission = new SitesPermission(data)
        callback() if typeof(callback) is 'function'

    @readable: (site) ->
      @sitesPermission.canRead(site)

    @updatePermission: (site, callback) ->
      @fetchSitesMembership =>
        canUpdate = @sitesPermission.canUpdate(site)
        field.writeable = (canUpdate and field.writeable) for field in @fields()
        callback() if typeof(callback) is 'function'
