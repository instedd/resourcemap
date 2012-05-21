#= require view_models/thresholds_view_model

describe 'ThresholdsViewModel', ->
  beforeEach ->
    @collectionId = 123
    @subject = new rm.ThresholdsViewModel @collectionId
    @threshold = new rm.Threshold { id: 1, priority: 1, color: 'red', conditions: [{ field: 'beds', is: 'lt', value: 12 }] }
    @threshold_2 = new rm.Threshold { id: 2, priority: 2, color: 'green', conditions: [{ field: 'doctors', is: 'lt', value: 2}] }
    @field = new rm.Field { name: 'Available Beds', code: 'beds', kind: 'numeric' }

  describe 'delete threshold', ->
    beforeEach ->
      @subject.thresholds [@threshold]

    it 'should show confirm dialog', ->
      spyOn window, 'confirm'
      @subject.deleteThreshold @threshold
      expect(window.confirm).toHaveBeenCalledWith rm.ThresholdsViewModel.Messages.DELETE_THRESHOLD

  describe 'cancel threshold', ->
    beforeEach ->
      @subject.state 'adding_new'
      @subject.currentThreshold @threshold

    it 'should remove current threshold', ->
      @subject.cancelThreshold()
      expect(@subject.currentThreshold()).toBeNull()

    it 'should reset state', ->
      @subject.cancelThreshold()
      expect(@subject.state()).toEqual 'listing'


  describe 'show threshold', ->
    beforeEach ->
      @subject.state 'listing'
      @subject.thresholds [ @threshold ]

    it 'should change threshold state to adding_new', ->
      @subject.showAddThreshold()
      expect(@subject.state()).toEqual 'adding_new' 

    it 'should add default to current threshold', ->
      @subject.showAddThreshold()
      expect(@subject.currentThreshold()).toBeTruthy()
       
        
  it 'should order threshold by priority', ->
    @subject.thresholds [@threshold_2, @threshold]
    @subject.refresh()
    expect(@subject.thresholds()[0]).toBe @threshold
    expect(@subject.thresholds()[1]).toBe @threshold_2

  describe 'moving threshold', ->
    beforeEach ->
      @subject.thresholds [@threshold, @threshold_2]

    describe 'up', ->
      it 'should change priority with above threshold', ->
        @subject.moveThresholdUp @threshold_2
        expect(@threshold_2.priority()).toEqual 1


        
      describe 'when it is on the top', ->
        it 'priority should not be changed', ->
          @subject.moveThresholdUp @threshold
          expect(@threshold.priority()).toEqual 1

    describe 'down', ->
      it 'should change priority with below threshold', ->
        @subject.moveThresholdDown @threshold
        expect(@threshold.priority()).toEqual 2

      describe 'when it is on the bottom', ->
        it 'priority should not be changed', ->
          @subject.moveThresholdDown @threshold_2
          expect(@threshold_2.priority()).toEqual 2

  describe 'edit threshold', ->
    beforeEach ->
      @subject.editThreshold @threshold

    it 'should be set as current threshold', ->
      expect(@subject.currentThreshold()).toBe @threshold

    it 'should change state to editing', ->
      expect(@subject.state()).toEqual 'editing'

  it 'should get field by code', ->
    @subject.fields [@field]
    expect(@subject.getField('beds')).toBe @field
