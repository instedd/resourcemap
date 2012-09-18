#= require collections/sites_permission
onCollections ->

  class @SitesMembership
    @constructorSitesMembership: ->
      @siteMembershipInitialized = false

    @fetchSitesMembership: ->
      unless @siteMembershipInitialized
        data =
          read :
            all_sites : true
            some_sites: []
          update :
            all_sites : false
            some_sites: [2]
        @sitesPermission = new SitesPermission(data)
        @siteMembershipInitialized = true

    @readable: (site) ->
      @sitesPermission.canRead(site)

    @updatePermission: (site) ->
      sitePermission = @sitesPermission.canUpdate(site)
      field.writeable = (sitePermission and field.writeable) for field in @fields()
