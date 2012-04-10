#= require models/threshold

describe 'Threshold', ->
  beforeEach ->
    @threshold = new rm.Threshold { priority: 1, color: '#ff0000', condition: {} }

  it 'should has priority', ->
    expect(@threshold.priority()).toEqual 1

  it 'should has color', ->
    expect(@threshold.color()).toEqual '#ff0000'

  it 'should has condition', ->
    expect(@threshold.condition()).toEqual {}
