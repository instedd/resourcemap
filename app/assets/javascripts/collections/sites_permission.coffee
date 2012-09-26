#= require collections/permission
onCollections ->

  class @SitesPermission
    constructor: (data) ->
      @read = new Permission(data['read'])
      @update = new Permission(data['update'])

    canRead: (site) ->
      @read.canAccess(site.id())

    canUpdate: (site) ->
      @update.canAccess(site.id())
