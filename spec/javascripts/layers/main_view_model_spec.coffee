describe 'Layer', ->
  beforeEach ->
    window.runOnCallbacks 'layers'

  describe 'MainViewModel', ->
    beforeEach ->
      @collectionId = 1
      @model = new MainViewModel @collectionId, []

    describe 'add new layer', ->
      beforeEach ->
        @model.newLayer()

      it 'should create new user field', ->
        @model.newUserField()
        expect(@model.currentField().kind()).toEqual 'user'
