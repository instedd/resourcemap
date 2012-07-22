describe 'Condition', ->
  beforeEach ->
    window.runOnCallbacks 'thresholds'

    @collectionId = 1
    window.model = new MainViewModel @collectionId
    window.model.fields [new Field id: 1, code: 'beds']
    @condition = new Condition field: '1', op: 'eq', value: 10, type: 'value'

  it 'should convert to json', ->
    expect(@condition.toJSON()).toEqual {field: '1', op: 'eq', value: 10, type: 'value', compare_field: '1'}

  describe 'formatted value', ->
    beforeEach ->
      @field = new Field id: 1, kind: 'numeric'
      spyOn(window.model, 'findField').andReturn @field

    it 'should format value', ->
      condition = new Condition field: '1', type: 'value', value: 12
      expect(condition.formattedValue()).toEqual '12'

    it 'should format percentage', ->
      condition = new Condition field: '1', type: 'percentage', value: 12
      expect(condition.formattedValue()).toEqual '12%'

    describe 'select', ->
      beforeEach ->
        options = [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}]
        @field.options $.map options, (option) -> new Option option

      describe '_one', ->
        beforeEach -> @field.kind 'select_one'

        it 'should get option label', ->
          condition = new Condition field: '1', value: 1
          expect(condition.formattedValue()).toEqual 'One'

      describe '_many', ->
        beforeEach -> @field.kind 'select_many'

        it 'should get option label', ->
          condition = new Condition field: '1', value: 2
          expect(condition.formattedValue()).toEqual 'Two'
