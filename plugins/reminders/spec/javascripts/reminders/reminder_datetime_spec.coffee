describe 'Reminders plugin', ->
  beforeEach ->
    window.runOnCallbacks 'reminders'

  describe 'Reminder datetime', ->
    beforeEach ->
      @date = new Date(2012, 7, 5, 5, 0)
      @reminderDateTime = new ReminderDateTime @date

    it 'should get date', ->
      expect(@reminderDateTime.getDate()).toEqual '2012-08-05'

    it 'should get time', ->
      expect(@reminderDateTime.getTime()).toEqual '05:00'

    it 'should convert to string', ->
      expect(@reminderDateTime.toString()).toEqual '2012-08-05T05:00'

    it 'should set date', ->
      @reminderDateTime.setDate '2012-08-01'
      expect(@reminderDateTime.getDate()).toEqual '2012-08-01'

    it 'should set time', ->
      @reminderDateTime.setTime '14:00'
      expect(@reminderDateTime.getTime()).toEqual '14:00'