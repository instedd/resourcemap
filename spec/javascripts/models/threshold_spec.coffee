#= require models/threshold

describe 'Threshold', ->
  beforeEach ->
    @threshold = new rm.Threshold { priority: 1, color: '#ff0000', condition: { field: 'beds', is: 'lt', value: 10 } }

  it 'should has priority', ->
    expect(@threshold.priority()).toEqual 1

  it 'should has color', ->
    expect(@threshold.color()).toEqual '#ff0000'

  it 'should has field', ->
    expect(@threshold.field()).toEqual 'beds'

  it 'should has comparison', ->
    expect(@threshold.comparison()).toEqual 'less than'

  it 'should has value', ->
    expect(@threshold.value()).toEqual 10

  describe 'with percentage value', ->
    beforeEach ->
      @threshold = new rm.Threshold { condition: { field: 'beds', is: 'lt', value: [0.75, 'doctors'] } }

    it 'should format to percentage', ->
      expect(@threshold.value()).toMatch /// 75\% ///

    it 'should display value', ->
      expect(@threshold.value()).toEqual '75% of doctors'

  describe '#destroy', ->
    it 'should dispatch ThresholdEvent:DESTROY event', ->
      spyOn rm.EventDispatcher, 'trigger'
      @threshold.destroy()
      expect(rm.EventDispatcher.trigger).toHaveBeenCalledWith rm.ThresholdEvent.DESTROY, new rm.ThresholdEvent @threshold
