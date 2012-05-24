describe 'Operator', ->
  beforeEach ->
    window.runOnCallbacks 'thresholds'

  it 'finds by code', ->
    expect(Operator.findByCode 'lt').toBe Operator.LT
