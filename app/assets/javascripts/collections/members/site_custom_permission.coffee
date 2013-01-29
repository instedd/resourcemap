class @SiteCustomPermission
  constructor: (id, name, read, write) ->
    @id = ko.observable id
    @name = ko.observable name
    @can_read = ko.observable read
    @can_write = ko.observable write

  @findBySiteName: (sitePermissions, site_name) ->
    _.find sitePermissions, (perm) -> perm.name() == site_name

  @findBySiteId: (sitePermissions, site_id) ->
    _.find sitePermissions, (perm) -> perm.id() == site_id


  # Expect "sitePermissions" to be an object like:
  #   "write":
  #     "all_sites": false
  #     "some_sites":[ {"id": "8376", "name": "Site 3"}]
  #   "read":
  #     "all_sites": true
  #     "some_sites": []
  @arrayFromJson: (sitePermissions) ->
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
      permissions = (new SiteCustomPermission site.id, site.name, true, can_write_all for site in sitePermissions.read.some_sites)

    unless can_write_all
      # Set write to true for all sites listed in write.some_sites that were also in read.some_sites
      permission.can_write(true) for permission in permissions when write(permission)

      # Create SiteCustomPermission instance for each site listed in write.some_sites that was not already created
      permissions = permissions.concat(new SiteCustomPermission site.id, site.name, true, true for site in sitePermissions.write.some_sites when not_in(permissions, site.id))

    permissions

