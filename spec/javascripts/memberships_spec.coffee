describe 'Membership', ->
  beforeEach ->
    @membership_json =
      "user_id": 1
      "user_display_name": "user1@mail.com"
      "admin": false
      "layers": []
      "sites": {}

    @rootViewModelStub = layers: -> []

    spyOn(SiteCustomPermission, 'arrayFromJson').andReturn []

  describe 'Some layers are forbidden for member (someLayersNone)', ->
    it 'should be false when member has at least read permission on all layers', ->
      @membership_json.layers = [
        {
          "layer_id": 53
          "read": true
          "write": false
        },
        {
          "layer_id": 56
          "read": true
          "write": true
        },
        {
          "layer_id": 58
          "read": true
          "write":false
        }
      ]

      membership = new Membership @rootViewModelStub, @membership_json
      expect(membership.someLayersNone()).toBe false

    it 'should be true when member has no permissions on one layer', ->
      @membership_json.layers = [
        {
          "layer_id": 53
          "read": true
          "write": false
        },
        {
          "layer_id": 56
          "read": false
          "write": false
        },
        {
          "layer_id": 58
          "read": true
          "write":false
        }
      ]

      membership = new Membership @rootViewModelStub, @membership_json
      expect(membership.someLayersNone()).toBe true

    it 'should be false when member has no permissions in any layer', ->
      @membership_json.layers = [
        {
          "layer_id": 53
          "read": false
          "write": false
        },
        {
          "layer_id": 56
          "read": false
          "write": false
        },
        {
          "layer_id": 58
          "read": false
          "write": false
        }
      ]

      membership = new Membership @rootViewModelStub, @membership_json
      expect(membership.someLayersNone()).toBe false

    it 'should be false when there are no layers', ->
      membership = new Membership @rootViewModelStub, @membership_json
      expect(membership.someLayersNone()).toBe false

  describe 'Know whether a member is admin or not (isNotAdmin)', ->
    it 'should be true when member is not admin', ->
      membership = new Membership @rootViewModelStub, @membership_json
      expect(membership.isNotAdmin()).toBe true

    it 'should be false when member is admin', ->
      @membership_json.admin = true
      membership = new Membership @rootViewModelStub, @membership_json
      expect(membership.isNotAdmin()).toBe false
