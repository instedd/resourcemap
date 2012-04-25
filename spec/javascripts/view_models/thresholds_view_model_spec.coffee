#= require view_models/thresholds_view_model

describe 'ThresholdsViewModel', ->
  beforeEach ->
    @collectionId = 123
    @subject = new rm.ThresholdsViewModel @collectionId
    @threshold = new rm.Threshold { id: 1, priority: 1, color: 'red', condition: { field: 'beds', is: 'lt', value: 12 } }

  describe 'delete threshold', ->
    beforeEach ->
      @subject.thresholds [ @threshold ]

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
