describe 'Site memberships plugin', ->
  beforeEach ->
    window.runOnCallbacks 'siteMemberships'
    @field = id: 2, name: 'Director'
    @membership = new Membership @field, {}

  describe 'Membership', ->
    it 'should have field', ->
      expect(@membership.field).toEqual @field
 
