#= require collections/sites_permission
onCollections ->

  class @SitesMembership
    @constructorSitesMembership: ->
      @siteMembershipInitialized = false

    @fetchSitesMembership: ->
      return if @siteMembershipInitialized

      $.get "collections/#{@id}/sites_permission", {}, (data) =>
        @sitesPermission = new SitesPermission(data)
        @siteMembershipInitialized = true

    @readable: (site) ->
      @sitesPermission.canRead(site)

    @updatePermission: (site) ->
      sitePermission = @sitesPermission.canUpdate(site)
      field.writeable = (sitePermission and field.writeable) for field in @fields()
