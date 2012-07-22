describe 'Thresholds', ->
  beforeEach ->
    window.runOnCallbacks 'collections'
    window.model = new MainViewModel
    window.model.initialize []

  describe 'MapViewModel', ->
    beforeEach ->
      @marker = new google.maps.Marker
      spyOn(@marker, 'setIcon')
      spyOn(@marker, 'setShadow')
      @model = window.model

    it 'should set marker custom icon', ->
      @marker.site = {'alert': 'true', 'icon': 'icon.png'}
      @model.setMarkerIcon @marker, 'active'
      expect(@marker.setIcon).toHaveBeenCalledWith(@model.markerImage('icon.png'))
      expect(@marker.setShadow).toHaveBeenCalledWith(null)
