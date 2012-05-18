describe 'Utils', ->

  describe 'convert hash into array', ->
    beforeEach ->
      @result = rm.Utils.hashToArray
        beds: 1
        doctors: 2

    it 'should have 2 items', ->
      expect(@result.length).toEqual 2

    describe 'item', ->
      it 'should has key field', ->
        expect(@result[0].key).toEqual 'beds'

      it 'should has value field', ->
        expect(@result[0].value).toEqual 1
