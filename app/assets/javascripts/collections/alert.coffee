onCollections ->
  # Represent a alert on the map.
  class @Alert extends google.maps.OverlayView
    constructor: (map, site) ->
      @map = map
      @setMap map
      @setData(site, false)

    onAdd: =>
      @div = document.createElement 'DIV'
      @div.className = 'threshold'
      @divClick = document.createElement 'DIV'
      @divClick.className = 'threshold-click'
      @adjustZIndex()
      @setActive false
      @setTarget() if @site.target

      @getPanes().overlayImage.appendChild @div
      @getPanes().overlayMouseTarget.appendChild @divClick
      return if @site.target 
      listenerDownCallback = =>
        @setMarkerIcon(@div, "resmap_#{@site.icon}_focus") 
        window.model.editSiteFromMarker(@site.id, @site.collection_id) 

      listenerUpCallback = =>
        #console.log 'up'

      @divDownListener = google.maps.event.addDomListener @divClick, 'mousedown', listenerDownCallback
      @divUpListener   = google.maps.event.addDomListener @divClick, 'mouseup', listenerUpCallback

    draw: =>
      pos = @getProjection().fromLatLngToDivPixel @position
      #@setMarkerIcon(@div,"resmap_#{@site.icon}")
      @div.style.left = "#{pos.x - 13}px" 
      @div.style.top  = "#{pos.y - 36}px"
      
      @divClick.style.left = "#{pos.x - 16}px" 
      @divClick.style.top  = "#{pos.y - 39}px"

      @divClick.style.border = "solid 3px #{@site.color}"
      if @startAs
        $(@div).addClass(@startAs)
        delete @startAs

    onRemove: =>
      google.maps.event.removeListener @divDownListener
      google.maps.event.removeListener @divUpListener
      @div.parentNode.removeChild @div
      @divClick.parentNode.removeChild @divClick
    
    setupListeners: =>
      if @divClick 
        listenerDownCallback = =>
          @setMarkerIcon(@div, "resmap_#{@site.icon}_focus") 
          window.model.editSiteFromMarker(@site.id, @site.collection_id) 

        listenerUpCallback = =>
          #console.log 'up'

        @divDownListener = google.maps.event.addDomListener @divClick, 'mousedown', listenerDownCallback
        @divUpListener   = google.maps.event.addDomListener @divClick, 'mouseup', listenerUpCallback

    deleteAlertMarkerListener: =>
      google.maps.event.removeListener @divDownListener
      google.maps.event.removeListener @divUpListener

    setActive: (draw = true) =>
      if @div
        @div.style.backgroundImage = "url(/assets/resmap_#{@site.icon}.png)"
        @draw if draw

    setTarget: =>
      if @div
        @setMarkerIcon(@div, "resmap_#{@site.icon}_focus")
    setInactive: (draw = true) =>
      if @div
        @setMarkerIcon(@div, "resmap_#{@site.icon}_inactive")
        #@div.style.backgroundImage = ""
        #   $(@div).removeClass('target')
        #   $(@div).addClass('inactive')
        # else
        #   @startAs = 'inactive'
    
    setMarkerIcon: (marker, icon)  =>
      marker.style.backgroundImage = "url(/assets/#{icon}.png)"

    adjustZIndex: =>
      zIndex = window.model.zIndex(@position.lat())
      @div.style.zIndex = zIndex if @div
      @divClick.style.zIndex = zIndex if @divClick

    setData: (site, draw = true) =>
      @position = new google.maps.LatLng(site.lat, site.lng)
      @site = site
      @setActive(true)
      @draw() if draw

