describe 'Collection', ->
  beforeEach ->
    window.runOnCallbacks 'collections'
    window.model = new MainViewModel

  describe 'CollectionsViewModel', ->
    beforeEach ->
      @collection = new Collection id: 1
      @model = window.model
      @model.initialize [@collection]

    it 'should not have current snapshot', ->
      expect(@model.currentSnapshot()).toBeUndefined()

    it 'should get current collection snapshot', ->
      @model.currentCollection @collection
      expect(@model.currentSnapshot()).toEqual ""
