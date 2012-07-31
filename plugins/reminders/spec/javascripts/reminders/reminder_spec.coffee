describe 'Reminders plugin', ->
  beforeEach ->
    window.runOnCallbacks 'reminders'
    @repeat = new Repeat name: 'Every Monday'

  describe 'Reminder', ->
    beforeEach ->
      @site_a = new Site name: 'Site A'
      @site_b = new Site name: 'Site B'
      @reminder = new Reminder name: 'Foo', collection_id: 1, repeat: @repeat

    it 'should have name', ->
      expect(@reminder.name()).toEqual('Foo')

    it 'should target for all sites', ->
      expect(@reminder.targetFor()).toEqual('all_sites')

    it 'should not have sites error', ->
      expect(@reminder.sitesError()).toBeUndefined()

    it 'should have reminder date', ->
      expect(@reminder.reminderDate()).not.toBeNull()

    it 'should have reminder time', ->
      expect(@reminder.reminderTime()).not.toBeNull()

    it 'should update reminder datetime when converting to json', ->
      @reminder.reminderDate '2012-07-25'
      json = @reminder.toJson()
      expect(json.reminder_date).toContain 'Jul 25 2012'

    it 'should get repeat name', ->
      expect(@reminder.repeatName()).toEqual 'Every Monday'

    it 'should get sites name', ->
      @reminder.sites [@site_a, @site_b]
      expect(@reminder.sitesName()).toEqual 'Site A, Site B'

    describe 'target for some sites', ->
      beforeEach ->
        @reminder.targetFor 'some_sites'

      it 'should change isAllSites', ->
        expect(@reminder.isAllSites()).toBeFalsy()

      it 'should have sites error', ->
        expect(@reminder.sitesError()).toEqual 'Sites is missing'

    describe '#errors', ->
      it 'should check name error', ->
        @reminder.name ''
        expect(@reminder.error()).toEqual "Reminder's name is missing"

      describe 'sites error', ->
        beforeEach ->
          @reminder.isAllSites false
          @reminder.reminderMessage 'Hello'

        it 'should have sites error', ->
          expect(@reminder.error()).toEqual "Sites is missing"

        it 'should not have sites error', ->
          @reminder.sites [@site_a]
          expect(@reminder.error()).toBeUndefined()

      it 'should check reminder date error', ->
        @reminder.reminderDate 'not-a-date'
        expect(@reminder.error()).toEqual "Reminder's date is invalid"

      it 'should check reminder message error', ->
        expect(@reminder.error()).toEqual "Reminder's message is missing"

    it 'should clone reminder', ->
      expect(@reminder.clone()).not.toBe @reminder