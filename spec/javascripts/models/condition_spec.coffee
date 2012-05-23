#= require models/condition

describe 'Condition', ->
  beforeEach ->
    @condition = new rm.Condition { field: 'beds', is: 'lt', value: 10 }

  it 'should has default type', ->
    expect(@condition.type()).toEqual 'value'

  it 'should has comparison description', ->
    expect(@condition.comparison()).toEqual 'is less than'

  it 'should has value', ->
    expect(@condition.value()).toEqual '10'

  it 'should format percent value', ->
    @condition.type 'percent'
    expect(@condition.value()).toEqual '10%'

  it 'should be valid', ->
    expect(@condition.valid()).toBeTruthy()
