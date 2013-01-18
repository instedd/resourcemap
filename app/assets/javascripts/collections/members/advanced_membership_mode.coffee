class @AdvancedMembershipMode
  constructor: (data)->
    @advancedMode = ko.observable(false)
    @sitesRead = new MembershipPermission('read', data.sites?.read)
    @sitesUpdate = new MembershipPermission('update', data.sites?.write)
    @error = ko.computed => @sitesRead.error() or @sitesUpdate.error()
    @validAdvancedMembership = ko.computed => !@error()


  advancedModeOn: =>
    @backupSitesPermission()
    @advancedMode(true)

  saveSitesPermission: =>
    $.post "/collections/#{collectionId}/sites_permission", sites_permission: user_id: @userId(), read: @sitesRead.toJson(), write: @sitesUpdate.toJson(), =>
      @deleteOriginalSitesPermission()
      @advancedMode(false)

  cancelAdvancedMembership: =>
    @restoreSitesPermission()
    @advancedMode(false)

  backupSitesPermission: =>
    @originalSitesRead = @sitesRead.clone()
    @originalSitesUpdate = @sitesUpdate.clone()

  restoreSitesPermission: =>
    @sitesRead = @originalSitesRead
    @sitesUpdate = @originalSitesUpdate
    @deleteOriginalSitesPermission()

  deleteOriginalSitesPermission: =>
    delete @originalSitesRead
    delete @originalSitesUpdate
