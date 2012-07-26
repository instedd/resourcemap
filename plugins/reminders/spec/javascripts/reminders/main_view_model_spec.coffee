describe 'Reminders plugin', ->
  beforeEach ->
    window.runOnCallbacks 'reminders'
    window.model = new MainViewModel @collectionId

  describe 'MainViewModel', ->
    beforeEach ->
      @collectionId = 1
      @reminder = new Reminder name: 'Foo', is_all_site: true
      @model = window.model
