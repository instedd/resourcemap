describe 'Reminders plugin', ->
  beforeEach ->
    window.runOnCallbacks 'reminders'
    @collectionId = 1
    window.model = new MainViewModel @collectionId
    @model = window.model

  describe 'MainViewModel', ->
    beforeEach ->
      @repeat = new Repeat id: 1, name: 'Every Weekday'
      @reminder = new Reminder id: 1, name: 'Foo', is_all_site: true, repeat: @repeat
      @model.repeats [@repeat]
      @model.reminders [@reminder]

    describe 'edit reminder', ->
      beforeEach -> @model.editReminder @reminder

      it 'should set current reminder', ->
        expect(@model.currentReminder()).toBe @reminder

      it 'should store original reminder', ->
        expect(@model.originalReminder).toBeDefined()
        expect(@model.originalReminder.id).toEqual 1
        expect(@model.originalReminder.name()).toEqual 'Foo'

      describe 'when modifing', ->
        beforeEach -> @model.currentReminder().name 'Bar'

        it 'should change underlaying reminder', ->
          expect(@model.reminders()[0].name()).toEqual 'Bar'

        it 'should not change original reminder', ->
          expect(@model.originalReminder.name()).toEqual 'Foo'

        describe 'when canceling', ->
          it 'should revert all unsaved changes', ->
            @model.cancelReminder()
            expect(@model.reminders()[0].name()).toEqual 'Foo'

    describe 'show add reminder', ->
      beforeEach -> @model.showAddReminder()

      it 'should add a new reminder into collection', ->
        expect(@model.reminders().length).toEqual 2
        expect(@model.reminders()[1].id).toBeUndefined()

      it 'should set new reminder as current reminder', ->
        expect(@model.reminders()[1]).toBe @model.currentReminder()

      describe 'when canceling', ->
        it 'should remove unsaved reminder', ->
          @model.cancelReminder()
          expect(@model.reminders().length).toEqual 1

    describe 'find repeat by id', ->
      it 'should find existing repeat', ->
        expect(@model.findRepeat 1).toBe @repeat

      it 'should not find non-existing repeat', ->
        expect(@model.findRepeat 12345).toBeUndefined()
