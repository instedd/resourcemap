describe 'Collection', ->
  beforeEach ->
    window.runOnCallbacks 'collections'
    window.model = new MainViewModel []
    @model = window.model

  describe 'MainViewModel', ->

    it 'should not show missing locations alert', ->
      # ... when there's not a current collection
      expect(@model.shouldShowLocationMissingAlert()).toBe(false)

      # ... when there's a current collection but no sites without location
      collection = new Collection id: 1
      @model.initialize [collection]
      @model.currentCollection collection
      @model.sitesWithoutLocation(false)
      expect(@model.shouldShowLocationMissingAlert()).toBe(false)

    it 'should show missing locations alert', ->
      collection = new Collection id: 1
      @model.initialize [collection]
      @model.currentCollection collection
      @model.sitesWithoutLocation(true)
      expect(@model.shouldShowLocationMissingAlert()).toBe(true)

    addSite = (site, collection) ->
      collection.addSite site(collection)

    siteWithoutLocation = (collection) ->
      site = new Site collection, id: 1
      site.position null
      site

    siteWithLocation = (collection) ->
      site = new Site collection, id: 1
      site.position lat: 1, lng: 1
      site
