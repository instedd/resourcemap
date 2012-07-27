describe "Date extensions", ->
  describe 'today', ->
    beforeEach ->
      @today = Date.today()

    it 'should be on this year', ->
      expect(@today.getFullYear()).toEqual (new Date()).getFullYear()

    it 'should be on this month', ->
      expect(@today.getMonth()).toEqual (new Date()).getMonth()

    it 'should be on this date', ->
      expect(@today.getDate()).toEqual (new Date()).getDate()

    it 'should be on 0 hour', ->
      expect(@today.getHours()).toEqual 0

    it 'should be on 0 minute', ->
      expect(@today.getMinutes()).toEqual 0

    it 'should be on 0 second', ->
      expect(@today.getSeconds()).toEqual 0

  describe "strftime", ->
    beforeEach ->
      @date = new Date('2012-08-02T05:30:00')

    it 'should format year', ->
      expect(@date.strftime '%Y').toEqual '2012'

    it 'should format month', ->
      expect(@date.strftime '%m').toEqual '08'

    it 'should format date', ->
      expect(@date.strftime '%d').toEqual '02'

    it 'should format hour', ->
      expect(@date.strftime '%H').toEqual '05'

    it 'should format minute', ->
      expect(@date.strftime '%M').toEqual '30'

    it 'should format second', ->
      expect(@date.strftime '%S').toEqual '00'

    it 'should format date string', ->
      expect(@date.strftime '%Y/%m/%d %H.%M').toEqual '2012/08/02 05.30'
