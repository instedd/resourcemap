describe 'Reminders plugin', ->
  beforeEach ->
    window.runOnCallbacks 'reminders'

    @collectionId = 1
    window.model = new MainViewModel @collectionId

  describe 'Reminder', ->
    beforeEach ->
      @reminder = new Reminder name: 'Foo'

    it 'should have name', ->
      expect(@reminder.name()).toEqual('Foo')

    it 'should target for all sites', ->
      expect(@reminder.targetFor()).toEqual('all_sites')

    it 'should not have sites error', ->
      expect(@reminder.sitesError()).toBeNull()

    it 'should have reminder date', ->
      expect(@reminder.reminderDate()).not.toBeNull()

    it 'should have reminder time', ->
      expect(@reminder.reminderTime()).not.toBeNull()

    it 'should update reminder datetime when converting to json', ->
      @reminder.reminderDate '2012-07-25'
      json = @reminder.toJson()
      expect(json.reminder_date).toContain 'Jul 25 2012'

    describe 'target for some sites', ->
      beforeEach ->
        @reminder.targetFor 'some_sites'

      it 'should change isAllSites', ->
        expect(@reminder.isAllSites()).toBeFalsy()

      it 'should have sites error', ->
        expect(@reminder.sitesError()).toEqual 'Sites is missing'