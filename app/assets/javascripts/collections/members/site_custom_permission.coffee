class @SiteCustomPermission
  constructor: (id, name, cannot_read, cannot_write, membership) ->
    @membership = membership
    @id = ko.observable id
    @name = ko.observable name
    @cannot_read = ko.observable cannot_read
    @cannot_write = ko.observable cannot_write

    @noneChecked = ko.computed
      read: =>
        if @cannot_read() and @cannot_write()
          "true"
        else
          "false"
      write: =>
        @cannot_read true
        @cannot_write true
        @membership.saveCustomSitePermissions()

    @readChecked = ko.computed
      read: =>
        if (not @cannot_read()) and @cannot_write()
          "true"
        else
          "false"
      write: =>
        @cannot_read false
        @cannot_write true
        @membership.saveCustomSitePermissions()

    @updateChecked = ko.computed
      read: =>
        if (not @cannot_read()) and (not @cannot_write())
          "true"
        else
          "false"
      write: =>
        @cannot_read false
        @cannot_write false
        @membership.saveCustomSitePermissions()


  @findBySiteName: (sitePermissions, site_name) ->
    _.find sitePermissions, (perm) -> perm.name() == site_name

  @findBySiteId: (sitePermissions, site_id) ->
    _.find sitePermissions, (perm) -> perm.id() == site_id


  @summarizeRead: (sitePermissions) ->
    read_sites = []
    read_sites = ({ "id": p.id(), "name": p.name() } for p in sitePermissions when p.cannot_read())
    { "all_sites": read_sites.length == 0, "some_sites": read_sites }

  @summarizeWrite: (sitePermissions) ->
    read_summary = @summarizeRead sitePermissions

    write_sites = []
    write_sites = ({ "id": p.id(), "name": p.name() } for p in sitePermissions when p.cannot_write())
    { "all_sites": write_sites.length == 0 and read_summary["all_sites"], "some_sites": write_sites }

  # Expect "sitePermissions" to be an object like:
  #   "write":
  #     "all_sites": false
  #     "some_sites":[ {"id": "8376", "name": "Site 3"}]
  #   "read":
  #     "all_sites": true
  #     "some_sites": []
  @arrayFromJson: (sitePermissions, membership) ->
    #some_sites in sitePermissions keep track of those sites that don't have permissions.
    write = (p) =>
      _.any(sitePermissions.write.some_sites, (s) -> s.id == p.id())

    not_in = (list, id) ->
      not _.any(list, (p) -> p.id() == id)

    return [] unless sitePermissions

    can_write_all = (not sitePermissions.write?) ||  sitePermissions.write.all_sites
    can_read_all = (not sitePermissions.read?) || sitePermissions.read.all_sites

    return [] if can_write_all and can_read_all

    permissions = []
    # Create a SiteCustomPermission instance for each site listed in read.some_sites
    unless can_read_all
      permissions = (new SiteCustomPermission(site.id, site.name, true, true, membership) for site in sitePermissions.read.some_sites)

    unless can_write_all
      # Create SiteCustomPermission instance for each site listed in write.some_sites that was not already created
      permissions = permissions.concat(new SiteCustomPermission(site.id, site.name,false,true,membership) for site in sitePermissions.write.some_sites when not_in(permissions, site.id))

    permissions


