onCollections ->

  # An object with a position on the map.
  class @Locatable
    @constructorLocatable: (data) ->
      @lat = ko.observable data?.lat
      @lng = ko.observable data?.lng
      @position = ko.computed
        read: => if @lat() && @lng() then new google.maps.LatLng(@lat(), @lng()) else null
        write: (latLng) =>
          if latLng == null then @lat(null); @lng(null); return
          if typeof(latLng?.lat) == 'function'
            @lat(latLng.lat()); @lng(latLng.lng())
          else
            @lat(latLng?.lat); @lng(latLng?.lng)
        owner: @

      @safe_lat = ko.computed => @safe_six_decimals_string_coordinate @lat()
      @safe_lng = ko.computed => @safe_six_decimals_string_coordinate @lng()

    # Pans the map to this object's location, and the reload the map's sites and clusters.
    @panToPosition: ->
      currentPosition = window.model.map.getCenter()
      positionChanged = @position() && (Math.abs(@position().lat() - currentPosition.lat()) > 1e-6 || Math.abs(@position().lng() - currentPosition.lng()) > 1e-6)

      window.model.reloadMapSitesAutomatically = false
      window.model.map.panTo @position() if positionChanged
      window.model.reloadMapSites()

    @safe_six_decimals_string_coordinate: (coord) ->
      if coord?
        strCoord = coord.toString()
        strCoord[0..strCoord.indexOf('.') + 7]
      else
        ''

