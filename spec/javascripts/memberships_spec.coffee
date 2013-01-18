describe 'Membership', ->
  describe 'Some layers are forbidden for member (someLayersNone)', ->
    beforeEach ->
      @membership_json = {"user_id":1,"user_display_name":"user1@mail.com","admin":false,"layers":[],"sites":{"write":{"all_sites":false,"some_sites":[{"id":"8376","name":"Site 3"}]},"read":{"all_sites":true,"some_sites":[]}}}

    it 'should be false when member has at least read permission on all layers', ->
      @membership_json.layers = [{"layer_id":53,"read":true,"write":false},{"layer_id":56,"read":true,"write":true},{"layer_id":58,"read":true,"write":false}]

      @membership = new Membership @membership_json

      expect(@membership.someLayersNone()).toBe false

    it 'should be true when member has no permissions on one layer', ->
      @membership_json.layers = [{"layer_id":53,"read":true,"write":false},{"layer_id":56,"read":false,"write":false},{"layer_id":58,"read":true,"write":false}]

      @membership = new Membership @membership_json

      _.each @membership.layers(), (l) -> console.log l.read()

      expect(@membership.someLayersNone()).toBe true

