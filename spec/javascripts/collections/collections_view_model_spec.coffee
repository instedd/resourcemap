describe 'Collection', ->
  beforeEach ->
    window.runOnCallbacks 'collections'

  describe 'CollectionsViewModel', ->
    beforeEach ->
      @collection = new Collection id: 1
      window.model = new MainViewModel [@collection]
      @model = window.model

    it 'should not have current snapshot', ->
      expect(@model.currentSnapshot()).toBeUndefined()

    it 'should get current collection snapshot', ->
      @model.currentCollection @collection
      expect(@model.currentSnapshot()).toEqual ""
