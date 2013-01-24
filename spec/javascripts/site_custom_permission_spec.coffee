describe 'SiteCustomPermission', ->
  describe 'Sites with custom permissions (sitesWithCustomPermissions)', ->
    it 'is empty json is null', ->
      sites = null
      expect(SiteCustomPermission.arrayFromJson(sites).length).toBe 0

    it 'is empty when all sites are readable AND writable', ->
      sites =
        "write":
          "all_sites": true
          "some_sites":[ {"id": "8376", "name": "Site 3"}]
        "read":
          "all_sites": true
          "some_sites": []

      expect(SiteCustomPermission.arrayFromJson(sites).length).toBe 0

    it 'has one element', ->
      sites =
        "write":
          "all_sites": false
          "some_sites":[ {"id": "8376", "name": "Site 3"}]
        "read":
          "all_sites": true
          "some_sites": []

      permissions = SiteCustomPermission.arrayFromJson(sites)

      expect(permissions.length).toBe 1
      expect(permissions[0].can_write()).toBe true
      expect(permissions[0].can_read()).toBe true
      expect(permissions[0].id()).toBe "8376"
      expect(permissions[0].name()).toBe "Site 3"

    it 'has two elements', ->
      sites =
        "write":
          "all_sites": false
          "some_sites":[ {"id": "8376", "name": "Site 3"}, {"id": "1283", "name": "Site 4"}]
        "read":
          "all_sites": true
          "some_sites": []

      permissions = SiteCustomPermission.arrayFromJson(sites)

      expect(permissions.length).toBe 2

    it 'some sites are writable, some others just readable', ->
      sites =
        "write":
          "all_sites": false
          "some_sites":[ {"id": "1283", "name": "Site 4"}]
        "read":
          "all_sites": false
          "some_sites": [ {"id": "8376", "name": "Site 3"}, {"id": "1283", "name": "Site 4"}]

      permissions = SiteCustomPermission.arrayFromJson(sites)

      expect(permissions.length).toBe 2
      expect(_.any(permissions, (p) -> p.id() == "1283" and p.can_read() and p.can_write())).toBe true
      expect(_.any(permissions, (p) -> p.id() == "8376" and p.can_read() and not p.can_write())).toBe true

    it 'works when write is null', ->
      sites =
        "write": null
        "read":
          "all_sites": false
          "some_sites": [ {"id": "8376", "name": "Site 3"}, {"id": "1283", "name": "Site 4"}]

      permissions = SiteCustomPermission.arrayFromJson(sites)

      expect(permissions.length).toBe 2
      expect(_.any(permissions, (p) -> p.id() == "1283" and p.can_read() and p.can_write())).toBe true
      expect(_.any(permissions, (p) -> p.id() == "8376" and p.can_read() and p.can_write())).toBe true

    it 'works when read is null', ->
      sites =
        "write":
          "all_sites": false
          "some_sites":[ {"id": "1283", "name": "Site 4"}]
        "read": null

      permissions = SiteCustomPermission.arrayFromJson(sites)

      expect(permissions.length).toBe 1
      expect(_.any(permissions, (p) -> p.id() == "1283" and p.can_read() and p.can_write())).toBe true


