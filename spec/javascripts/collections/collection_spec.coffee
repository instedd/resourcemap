describe 'Collection', ->
  beforeEach ->
    window.runOnCallbacks 'collections'
    window.model = new MainViewModel
    window.model.initialize []

  describe 'collection', ->
    beforeEach ->
      @collection = new Collection id: 1

    it 'should get searchUsersUrl', ->
      expect(@collection.searchUsersUrl()).toEqual '/collections/1/memberships/search.json'
