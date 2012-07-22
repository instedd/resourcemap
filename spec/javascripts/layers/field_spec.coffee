describe 'Layer', ->
  beforeEach ->
    window.runOnCallbacks 'layers'
    @layer = new Layer

  describe 'Field', ->
    describe 'kind of user', ->
      beforeEach ->
        @field = new Field @layer, kind: 'user'

      it 'should have buttonClass "user"', ->
        expect(@field.buttonClass()).toEqual 'luser'
