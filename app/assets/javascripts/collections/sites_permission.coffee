#= require collections/permission
onCollections ->

  class @SitesPermission
    constructor: (data) ->
      @read = new Permission(data['read'])
      @write = new Permission(data['write'])

    canRead: (site) ->
      @read.canAccess(site.id())

    canUpdate: (site) ->
      @write.canAccess(site.id())
