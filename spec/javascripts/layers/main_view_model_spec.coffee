describe 'Layer', ->
  beforeEach ->
    window.runOnCallbacks 'layers'

  describe 'MainViewModel', ->
    beforeEach ->
      @model = new MainViewModel 1, []

    describe 'new layer', ->
      beforeEach ->
        @model.newLayer()

      it 'should create new field', ->
        @model.newField 'kind'
        expect(@model.currentField().kind()).toEqual 'kind'




