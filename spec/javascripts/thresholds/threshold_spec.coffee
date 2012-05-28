describe 'Threshold', ->
  beforeEach ->
    window.runOnCallbacks 'thresholds'

    @collectionId = 1
    window.model = new MainViewModel @collectionId
    @field_beds = new Field id: '1', code: 'beds'
    window.model.fields [@field_beds]
    @threshold = new Threshold { collection_id: 1, priority: 1, color: '#ff0000', conditions: [{ field: '1', op: 'lt', type: 'value', value: 10 }] }

  it 'should have 1 condition', ->
    expect(@threshold.conditions().length).toEqual 1

  it 'should be valid', ->
    expect(@threshold.valid()).toBeTruthy()

  it 'should not be valid when have invalid condition', ->
    @threshold.conditions()[0].value null
    expect(@threshold.valid()).toBeFalsy()

  it 'should convert to json', ->
    @threshold.id(1)
    expect(@threshold.toJSON()).toEqual {
      id: 1
      color: '#ff0000'
      conditions: [{field: '1', op: 'lt', value: 10, type: 'value'}]
    }

  describe 'without data', ->
    beforeEach ->
      @threshold = new Threshold {}

    it 'should default threshold have no conditions', ->
      expect(@threshold.conditions().length).toEqual 0

    it 'should not be valid', ->
      expect(@threshold.valid()).toBeFalsy()

  it 'should check is first condtion', ->
    @threshold.isFirstCondition @threshold.conditions()[0]

  it 'should check is last condtion', ->
    @threshold.isLastCondition @threshold.conditions()[0]

  it 'should add condition', ->
    spyOn(window.model, 'findField').andReturn @field_beds
    @threshold.addNewCondition()
    expect(@threshold.conditions().length).toEqual 2

  it 'should remove condition', ->
    @threshold.removeCondition @threshold.conditions()[0]
    expect(@threshold.conditions().length).toEqual 0
