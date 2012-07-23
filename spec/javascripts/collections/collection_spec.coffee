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

  describe 'collection sites', ->
    it 'should get sites without location', ->
      @collection = new Collection id: 2
      siteLoc = new Site @collection, id: 63, lat: 2.9697599999999986, lng: 37.56265600000006, name: "Site w Loc", type: "site", updated_at: "2012-07-11T13:46:22-05:00", created_at: "2012-07-11T13:46:22-05:00"
      siteNoLoc = new Site @collection, id: 64, name: "Site w no Loc", type: "site", updated_at: "2012-07-11T13:46:22-05:00", created_at: "2012-07-11T13:46:22-05:00"

      @collection.addSite(siteLoc)
      @collection.addSite(siteNoLoc)

      sitesNoLoc = @collection.sitesWithoutLocation()

      expect(sitesNoLoc.length).toEqual 1
      expect(sitesNoLoc[0].name()).toEqual 'Site w no Loc'
      expect(sitesNoLoc[0].locationText()).toEqual ''




