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

    describe 'target for some sites', ->
      beforeEach ->
        @reminder.targetFor 'some_sites'

      it 'should change isAllSites', ->
        expect(@reminder.isAllSites()).toBeFalsy()

      it 'should have sites error', ->
        expect(@reminder.sitesError()).toEqual 'Sites is missing'