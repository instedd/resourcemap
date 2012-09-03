describe 'Site memberships plugin', ->
  beforeEach ->
    window.runOnCallbacks 'siteMemberships'
    @collectionId = 1
    window.model = new MainViewModel @collectionId
    @model = window.model

  describe 'MainViewModel', ->
    it 'should have collectionId', ->
      expect(@model.collectionId).toEqual @collectionId
