onCollections ->

  # An object with a position on the map.
  class @Locatable
    @constructorLocatable: (data) ->
      @lat = ko.observable data?.lat
      @lng = ko.observable data?.lng
      @position = ko.computed
        read: => if @lat() && @lng() then new google.maps.LatLng(@lat(), @lng()) else null
        write: (latLng) =>
          if typeof(latLng.lat) == 'function'
            @lat(latLng.lat()); @lng(latLng.lng())
          else
            @lat(latLng.lat); @lng(latLng.lng)
        owner: @

    # Pans the map to this object's location, and the reload the map's sites and clusters.
    @panToPosition: ->
      currentPosition = window.model.map.getCenter()
      positionChanged = @position() && (Math.abs(@position().lat() - currentPosition.lat()) > 1e-6 || Math.abs(@position().lng() - currentPosition.lng()) > 1e-6)

      window.model.reloadMapSitesAutomatically = false
      window.model.map.panTo @position() if positionChanged
      window.model.reloadMapSites()
