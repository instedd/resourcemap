describe 'ValueType', ->
  beforeEach ->
    window.runOnCallbacks 'thresholds'

  it 'finds by code', ->
    expect(ValueType.findByCode 'value').toBe ValueType.VALUE

