describe "String extensions", ->
  it 'should check for valid date', ->
    expect('2012-07-27'.isDate()).toBeTruthy()

  it 'should check for invalid date', ->
    expect('foo'.isDate()).toBeFalsy()

  describe 'format', ->
    it 'should append leading 0', ->
      expect(String.format 8, 2).toEqual '08'

    it 'should customize leading character', ->
      expect(String.format 8, 5, '#').toEqual '####8'

    it 'should not change original value', ->
      expect(String.format 98, 1).toEqual '98'
