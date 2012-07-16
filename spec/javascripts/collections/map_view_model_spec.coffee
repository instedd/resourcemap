describe 'Collection', ->
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

    it 'should set marker icon to null', ->
      @model.setMarkerIcon @marker, 'null'
      expect(@marker.setIcon).toHaveBeenCalledWith(null)
      expect(@marker.setShadow).toHaveBeenCalledWith(null)

    it 'should set marker custom icon', ->
      @model.setMarkerIcon @marker, 'icon.png'
      expect(@marker.setIcon).toHaveBeenCalledWith(@model.markerImage('icon.png'))
      expect(@marker.setShadow).toHaveBeenCalledWith(null)
