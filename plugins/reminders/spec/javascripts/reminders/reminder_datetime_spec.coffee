describe 'Reminders plugin', ->
  beforeEach ->
    window.runOnCallbacks 'reminders'

  describe 'Reminder datetime', ->
    beforeEach ->
      @datetime = new ReminderDateTime ''
      @now = new Date()

    it 'should get date', ->
      expect(@datetime.getDate()).toEqual @now.strftime '%Y-%m-%d'

    it 'should get time', ->
      expect(@datetime.getTime()).toEqual '00:00'

    it 'should convert to string', ->
      expect(@datetime.toString().isDate()).toBeTruthy()

    it 'should set date', ->
      @datetime.setDate '2012-08-01'
      expect(@datetime.getDate()).toEqual '2012-08-01'

    it 'should set time', ->
      @datetime.setTime '14:00'
      expect(@datetime.getTime()).toEqual '14:00'
