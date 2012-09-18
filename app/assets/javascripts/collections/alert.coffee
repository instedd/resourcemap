onCollections ->
  # Represent a alert on the map.
  class @Alert extends google.maps.OverlayView
    constructor: (map, site) ->
      @map = map
      @setMap map
      console.log site 
      @setData(site, false)

    onAdd: =>
      @div = document.createElement 'DIV'
      @div.className = 'threshold'
      @divClick = document.createElement 'DIV'
      @divClick.className = 'threshold-click'
      @adjustZIndex()

      @setActive false
      @getPanes().overlayImage.appendChild @div
      @getPanes().overlayMouseTarget.appendChild @divClick
      
      listenerDownCallback = =>
        @setInactive()
        @divClick.style.backgroundImage = ""
        window.model.editSiteFromMarker(@site.id, @site.collection_id) 

      listenerUpCallback = =>
        #console.log 'up'

      @divDownListener = google.maps.event.addDomListener @divClick, 'mousedown', listenerDownCallback
      @divUpListener   = google.maps.event.addDomListener @divClick, 'mouseup', listenerUpCallback

    draw: =>
      pos = @getProjection().fromLatLngToDivPixel @position
      @div.style.backgroundImage = "url(/assets/resmap_#{@site.icon}.png)"
      @div.style.left = @divClick.style.left = "#{pos.x - 13}px" 
      @div.style.top  = @divClick.style.top  = "#{pos.y - 36}px"
      
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

    setActive: (draw = true) =>
      if @div
        @div.style.backgroundImage = "url(/assets/resmap_#{@site.icon}.png)"
      #  $(@div).removeClass('target')
      #  $(@div).removeClass('inactive')
        @draw if draw

    setInactive: (draw = true) =>
      if @div
        @div.style.backgroundImage = ""
      #   $(@div).removeClass('target')
      #   $(@div).addClass('inactive')
      # else
      #   @startAs = 'inactive'
    
    
    adjustZIndex: =>
      zIndex = window.model.zIndex(@position.lat())
      @div.style.zIndex = zIndex if @div

    setData: (site, draw = true) =>
      @position = new google.maps.LatLng(site.lat, site.lng)
      @site = site
      @setActive(true)
      @draw() if draw

