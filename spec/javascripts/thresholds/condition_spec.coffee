describe 'Condition', ->
  beforeEach ->
    window.runOnCallbacks 'thresholds'

    @collectionId = 1
    window.model = new MainViewModel @collectionId
    window.model.fields [new Field id: 1, code: 'beds']
    @condition = new Condition field: '1', op: 'eq', value: 10, type: 'value'

  it 'should convert to json', ->
    expect(@condition.toJSON()).toEqual {field: '1', op: 'eq', value: 10, type: 'value'}

