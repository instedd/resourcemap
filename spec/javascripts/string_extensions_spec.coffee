describe "String extensions", ->
  describe '#toDate', ->
    it 'should convert from ISO 8601 date String', ->
      date = '2012-07-27T05:00:00Z'.toDate()
      expect(date.getUTCFullYear()).toEqual 2012
      expect(date.getUTCMonth()).toEqual 6
      expect(date.getUTCDate()).toEqual 27
      expect(date.getUTCHours()).toEqual 5
      expect(date.getUTCMinutes()).toEqual 0
      expect(date.getUTCSeconds()).toEqual 0

    it 'should not convert invalid date string', ->
      expect('not-a-date'.toDate()).toEqual null

  describe 'format', ->
    it 'should append leading 0', ->
      expect(String.format 8, 2).toEqual '08'

    it 'should customize leading character', ->
      expect(String.format 8, 5, '#').toEqual '####8'

    it 'should not change original value', ->
      expect(String.format 98, 1).toEqual '98'