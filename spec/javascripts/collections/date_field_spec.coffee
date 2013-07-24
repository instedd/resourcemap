describe 'Collection', ->
  beforeEach ->
    window.runOnCallbacks 'collections'
    window.model = new MainViewModel []

  describe 'Field', ->
    beforeEach ->
      editingSite = updateProperty: ->
      window.model.editingSite = -> editingSite
      window.model.initAutocomplete = -> true

    describe 'Date Field With MM/DD/YYYY', ->
      beforeEach ->
        @field = new Field { id: 1, code: 'creation', name: 'Creation', kind: 'date' }
        @field.setValueFromSite('1012-12-26T03:00:00Z')

      it 'should have value when set one', ->
        expect(@field.hasValue()).toBeTruthy()

      it 'should not fail when no value is selected', ->
        @field.value(undefined)
        expect(@field.value()).toEqual(undefined)

      it 'should get value for ui', ->
        expect(@field.valueUI()).toEqual('12/26/1012')

      it 'value should be the in date_picker_format if valueUI changes', ->
        @field.valueUI('12/25/1012')
        expect(@field.value()).toEqual('12/25/1012')
        expect(@field.valueUI()).toEqual('12/25/1012')

    describe 'Date Field With DD/MM/YYYY', ->
      beforeEach ->
        @field = new Field { id: 1, code: 'creation', name: 'Creation', kind: 'date', config: { format: "dd_mm_yyyy" } }
        @field.setValueFromSite('1012-12-26T03:00:00Z')

      it 'should convert isoValue into the configured format', ->
        expect(@field.value()).toEqual('26/12/1012')

      it 'should have value when set one', ->
        expect(@field.hasValue()).toBeTruthy()

      it 'should not fail when no value is selected', ->
        @field.value(undefined)
        expect(@field.value()).toEqual(undefined)


