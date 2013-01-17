describe 'Membership', ->
  describe 'Admin', ->
    beforeEach ->
      @current_user_id = 1
      @collection_id = 1
      @is_admin = true
      @layers = [{"id":53, "name":"Layer1"},{"id":56, "name":"Layer2"},{"id":58, "name":"Layer3"}]

      @memberships = [{"user_id":2, "user_display_name":"user2@mail.com","admin":true,"layers":[],"sites":{"read":null,"write":null}}, {"user_id":1,"user_display_name":"user1@mail.com","admin":false,"layers":[{"layer_id":53,"read":true,"write":false},{"layer_id":56,"read":true,"write":true},{"layer_id":58,"read":true,"write":false}],"sites":{"write":{"all_sites":false,"some_sites":[{"id":"8376","name":"Site 3"}]},"read":{"all_sites":true,"some_sites":[]}}},{"user_id":7,"user_display_name":"user3@mail.com","admin":false,"layers":[],"sites":{"read":{"all_sites":false,"some_sites":[{"id":"8376","name":"Site 3"},{"id":"11487","name":"Site 4"}]},"write":{"all_sites":false,"some_sites":[{"id":"11487","name":"Site 4"}]}}}]

      window.initMemberships @current_user_id, @collection_id, @is_admin, @layers

  it 'should set someLayersNone to false when all layers have read permission', ->
    @membership = new Membership
    @membership.initialize @memberships

