describe 'Collection', ->
  beforeEach ->
    window.runOnCallbacks 'collections'
    window.model = new MainViewModel
    window.model.initialize []

  describe 'Field', ->
    beforeEach ->
      editingSite = updateProperty: ->
      window.model.editingSite = -> editingSite
      window.model.initAutocomplete = -> true

    describe 'Generic Field', ->
      beforeEach ->
        @field = new Field { id: 1, code: 'beds', name: 'Available beds', kind: 'numeric', writeable: true }

      it 'should have an esCode', ->
        expect(@field.esCode).toEqual('1')

      it 'should have a code', ->
        expect(@field.code).toEqual('beds')

      it 'should have a name', ->
        expect(@field.name).toEqual('Available beds')

      it 'should have a kind', ->
        expect(@field.kind).toEqual('numeric')

      it 'should have a writeable', ->
        expect(@field.writeable).toBeTruthy()

      it 'should have a value', ->
        @field.value(123)
        expect(@field.value()).toEqual(123)

      it 'should not be editing', ->
        expect(@field.editing()).toBeFalsy()

      it 'should not have a value', ->
        expect(@field.hasValue()).toBeFalsy()

      it 'get code for line when api is false', ->
        expect(@field.codeForLink()).toEqual('1')

      it 'get code for line when api is true', ->
        expect(@field.codeForLink(true)).toEqual('beds')

      it 'should expand', ->
        @field.expand()
        expect(@field.expanded()).toBeTruthy()

      it 'gets suggested width when name length is more than 10', ->
        expect(@field.suggestedWidth()).toEqual('132px')

      it 'gets suggested width when name length is less than 10', ->
        @field.name = 'Foo'
        expect(@field.suggestedWidth()).toEqual('100px')

      it 'should edit and cancel', ->
        @field.value(123)
        @field.edit()
        expect(@field.editing()).toBeTruthy()
        @field.value(456)
        @field.exit()
        expect(@field.value()).toEqual(123)
        expect(@field.editing()).toBeFalsy()

      it 'should edit and save', ->
        spyOn(window.model.editingSite(), 'updateProperty')

        @field.edit()
        @field.value(123)
        @field.save()

        expect(window.model.editingSite().updateProperty).toHaveBeenCalledWith('1', 123)

    describe 'Numeric Field', ->
      beforeEach ->
        @field = new Field { id: 1, code: 'beds', name: 'Available beds', kind: 'numeric' }
        @field.value(123)

      it 'should have value when set one', ->
        expect(@field.hasValue()).toBeTruthy()

      it 'should get value for ui', ->
        expect(@field.valueUI()).toEqual(123)

    describe 'Text Field', ->
      beforeEach ->
        @field = new Field { id: 1, code: 'profession', name: 'Profession', kind: 'text' }
        @field.value('foo')

      it 'should have value when set one', ->
        expect(@field.hasValue()).toBeTruthy()

      it 'should get value for ui', ->
        expect(@field.valueUI()).toEqual('foo')

    describe 'Select One Field', ->
      beforeEach ->
        @field = new Field { id: 1, code: 'color', name: 'Color', kind: 'select_one', config:
          {options: [
            {id: 1, code: 'red', label: 'Red'},
            {id: 2, code: 'green', label: 'Green'},
          ]}
        }

      it 'should not have a value', ->
        expect(@field.hasValue()).toBeFalsy()

      it 'should have value when set one', ->
        @field.value(1)
        expect(@field.hasValue()).toBeTruthy()

      it 'should get value for ui', ->
        @field.value(2)
        expect(@field.valueUI()).toEqual('Green')

      it 'should have options', ->
        expect(@field.options.length).toEqual(2)


      it 'should have optionsIds', ->
        expect(@field.optionsIds).toEqual([1, 2])

    describe 'Select Many Field', ->
      beforeEach ->
        @field = new Field { id: 1, code: 'color', name: 'Color', kind: 'select_many', config:
          {options: [
            {id: 1, code: 'red', label: 'Red'},
            {id: 2, code: 'green', label: 'Green'},
            {id: 3, code: 'blue', label: 'Blue'},
          ]}
        }

      it 'should not have a value', ->
        @field.value([])
        expect(@field.hasValue()).toBeFalsy()

      it 'should have value when set one', ->
        @field.value([1, 3])
        expect(@field.hasValue()).toBeTruthy()

      it 'should get value for ui', ->
        @field.value([1, 3])
        expect(@field.valueUI()).toEqual('Red, Blue')

      it 'should have options', ->
        expect(@field.options.length).toEqual(3)

      it 'should have optionsIds', ->
        expect(@field.optionsIds).toEqual([1, 2, 3])

      it 'should have all remaining options', ->
        expect(@field.remainingOptions()).toEqual(@field.options)

      it 'should select one option', ->
        @field.selectOption(@field.options[0])
        expect(@field.value()).toEqual([1])
        expect(@field.remainingOptions()).toEqual([@field.options[1], @field.options[2]])

      it 'should select two options', ->
        @field.selectOption(@field.options[0])
        @field.selectOption(@field.options[2])
        expect(@field.value()).toEqual([1, 3])
        expect(@field.remainingOptions()).toEqual([@field.options[1]])

      it 'should remove an option', ->
        @field.value([1, 3])
        @field.removeOption(3)
        expect(@field.value()).toEqual([1])
        expect(@field.remainingOptions()).toEqual([@field.options[1], @field.options[2]])

    describe 'Date Field', ->
      beforeEach ->
        @field = new Field { id: 1, code: 'creation', name: 'Creation', kind: 'date' }
        @field.value('1012-12-26T03:00:00.000Z')

      it 'should have value when set one', ->
        expect(@field.hasValue()).toBeTruthy()

      it 'should not fail when no value is selected', ->
        @field.value(undefined)
        expect(@field.value()).toEqual(undefined)

      it 'should get value for ui', ->
        expect(@field.valueUI()).toEqual('12/26/1012')

      it 'should read and write valueUI and change value', ->
        @field.valueUI('12/25/1012')
        isoValue = (new Date('12/25/1012')).toISOString()
        expect(@field.value()).toEqual(isoValue)
        expect(@field.valueUI()).toEqual('12/25/1012')

    describe 'Site Field', ->
      beforeEach ->
        @field = new Field { id: 1, code: 'techreference', name: 'Reference', kind: 'site' }

      it 'should delete value', ->
        #This works only because current collection is undefined
        @field.valueUI("")
        expect(@field.value()).toEqual('')


    describe 'Plugin field', ->
      beforeEach ->
        @email_field = new Field id: 2, code: 'email', name: 'Email', kind: 'email'
        @phone_field = new Field id: 3, code: 'phone', name: 'Phone', kind: 'phone'
        @text_field = new Field id: 4, code: 'text', name: 'Text', kind: 'text'

      it 'email field should be plugin kind', ->
        expect(@email_field.isPluginKind()).toBeTruthy()

      it 'phone field should be plugin kind', ->
        expect(@phone_field.isPluginKind()).toBeTruthy()

      it 'text field should not be plugin kind', ->
        expect(@text_field.isPluginKind()).toBeFalsy()
