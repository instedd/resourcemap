#= require view_models/thresholds_view_model

describe 'ThresholdsViewModel', ->
  beforeEach ->
    @subject = new rm.ThresholdsViewModel

  describe 'delete threshold', ->
    beforeEach ->
      @threshold = new rm.Threshold { id: 1, priority: 1, color: 'red', condition: { field: 'beds', is: 'lt', value: 12 } }
      @subject.thresholds [ @threshold ]

    it 'should show confirm dialog', ->
      spyOn window, 'confirm'
      @subject.deleteThreshold @threshold
      expect(window.confirm).toHaveBeenCalledWith rm.ThresholdsViewModel.Messages.DELETE_THRESHOLD
