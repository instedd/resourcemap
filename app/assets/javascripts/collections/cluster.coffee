onCollections ->

  # Repesents a cluster on the map.
  # It consists of a location and a count.
  class @Cluster extends google.maps.OverlayView
    constructor: (map, cluster) ->
      @map = map
      @setMap map
      @setData(cluster, false)

    onAdd: =>
      @div = document.createElement 'DIV'
      @div.className = 'cluster'
      @shadow = document.createElement 'DIV'
      @shadow.className = 'cluster-shadow'
      @countDiv = document.createElement 'DIV'
      @countDiv.className = 'cluster-count'
      @setCount @count
      @setAlertCount @alertCount

      @divClick = document.createElement 'DIV'
      @divClick.className = 'cluster-click'

      @countClick = document.createElement 'DIV'
      @countClick.className = 'cluster-count-click'

      @adjustZIndex()
      @setActive(false)

      @getPanes().overlayImage.appendChild @div
      @getPanes().overlayImage.appendChild @countDiv
      @getPanes().overlayShadow.appendChild @shadow
      @getPanes().overlayMouseTarget.appendChild @divClick
      @getPanes().overlayMouseTarget.appendChild @countClick

      # Instead of a listener for click we create two listeners for mousedown and mouseup:
      # If the user clicks a cluster and drags it, we want to drag the map but not zoom in
      listenerDownCallback = =>
        @originalLatLng = window.model.map.getCenter()

      listenerUpCallback = =>
        center = window.model.map.getCenter()
        if !@originalLatLng || (@originalLatLng.lat() == center.lat() && @originalLatLng.lng() == center.lng())
          @map.fitBounds @bounds

      @divDownListener = google.maps.event.addDomListener @divClick, 'mousedown', listenerDownCallback
      @divUpListener = google.maps.event.addDomListener @divClick, 'mouseup', listenerUpCallback

      @countDownListener = google.maps.event.addDomListener @countClick, 'mousedown', listenerDownCallback
      @countUpListener = google.maps.event.addDomListener @countClick, 'mouseup', listenerUpCallback

    draw: =>
      pos = @getProjection().fromLatLngToDivPixel @position
      @div.style.left = @divClick.style.left = "#{pos.x - 13}px"
      @div.style.top = @divClick.style.top = "#{pos.y - 36}px"
      @shadow.style.left = "#{pos.x - 7}px"
      @shadow.style.top = "#{pos.y - 36}px"

      # If the count on the cluster is too big (more than 3 digits)
      # we move the div containing the count to the left
      @digits = Math.floor(2 * Math.log(@count / 10) / Math.log(10));
      @digits = 0 if @digits < 0
      @countDiv.style.left = @countClick.style.left = "#{pos.x - 12 - @digits}px"
      @countDiv.style.top = @countClick.style.top = "#{pos.y + 2}px"

      if @startAs
        $(@div).addClass(@startAs)
        delete @startAs

    onRemove: =>
      google.maps.event.removeListener @divDownListener
      google.maps.event.removeListener @divUpListener
      google.maps.event.removeListener @countDownListener
      google.maps.event.removeListener @countUpListener
      @div.parentNode.removeChild @div
      @shadow.parentNode.removeChild @shadow
      @countDiv.parentNode.removeChild @countDiv
      @divClick.parentNode.removeChild @divClick
      @countClick.parentNode.removeChild @countClick

    setData: (cluster, draw = true) =>
      @position = new google.maps.LatLng(cluster.lat, cluster.lng)
      @bounds = new google.maps.LatLngBounds(
        new google.maps.LatLng(cluster.min_lat, cluster.min_lng),
        new google.maps.LatLng(cluster.max_lat, cluster.max_lng)
      )
      @setCount cluster.count
      @setAlertCount cluster.alert_count
      @draw() if draw

    setCount: (count) =>
      @count = count
      @countDiv.innerHTML = (@count).toString() if @countDiv

    setAlertCount: (alertCount) =>
      @alertCount = alertCount

    setActive: (draw = true) =>
      if @div
        $(@div).removeClass('target')
        $(@div).removeClass('inactive')
        @draw() if draw

    setInactive: (draw = true) =>
      if @div
        $(@div).removeClass('target')
        $(@div).addClass('inactive')
        @draw() if draw
      else
        @startAs = 'inactive'

    setTarget: (draw = true) =>
      if @div
        $(@div).removeClass('inactive')
        $(@div).addClass('target')
        @draw() if draw
      else
        @startAs = 'target'

    adjustZIndex: =>
      zIndex = window.model.zIndex(@position.lat())
      @div.style.zIndex = zIndex if @div
      @countDiv.style.zIndex = zIndex - 10 if @countDiv
