describe 'Threshold', ->
  beforeEach ->
    window.runOnCallbacks 'thresholds'

  describe 'Field', ->
    describe 'kind is text', ->
      beforeEach ->
        @field = new Field kind: 'text'

      it 'should have equal to operator', ->
        expect(@field.operators()).toContain Operator.EQ

      it 'should have contain operator', ->
        expect(@field.operators()).toContain Operator.CON

    describe 'kind is numeric', ->
      beforeEach ->
        @field = new Field kind: 'numeric'

      it 'should have equal to operator', ->
        expect(@field.operators()).toContain Operator.EQ

      it 'should have less than operator', ->
        expect(@field.operators()).toContain Operator.LT

      it 'should have larger than operator', ->
        expect(@field.operators()).toContain Operator.GT

    describe 'kind is select one', ->
      beforeEach ->
        @field = new Field kind: 'select_one', config: {options: [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}]}

      it 'should has is operator', ->
        expect(@field.operators()).toContain Operator.EQ

      it 'should have options', ->
        expect(@field.options().length).toEqual 2

    describe 'kind is select many', ->
      beforeEach ->
        @field = new Field kind: 'select_many'

      it 'should has is operator', ->
        expect(@field.operators()).toContain Operator.EQ
