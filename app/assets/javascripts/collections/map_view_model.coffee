onCollections ->

  class @MapViewModel
    @constructor: ->
      @showingMap = ko.observable(true)
      @sitesCount = ko.observable(0)
      @sitesCountText = ko.computed => if @sitesCount() == 1 then '1 site' else "#{@sitesCount()} sites"
      @sitesChangedListeners = []

      @reloadMapSitesAutomatically = true
      @clusters = {}
      @alertMarkers = {}
      @siteIds = {}
      @mapRequestNumber = 0
      @geocoder = new google.maps.Geocoder()

      # change to use dynamic icon from collection 
      #@markerImageInactive = @markerImage 'marker_inactive.png'
      #@markerImageTarget = @markerImage 'marker_target.png'
     


      #@markerImageInactiveShadow = @markerImageShadow 'marker_inactive.png'
      #@markerImageTargetShadow = @markerImageShadow 'marker_target.png'

      $.each @collections(), (idx) =>
        @collections()[idx].checked.subscribe (newValue) =>
          @reloadMapSites()

      @showingMap.subscribe =>
        @rewriteUrl()

    @initMap: ->
      return true unless @showingMap()
      return false if @map

      center = if @queryParams.lat && @queryParams.lng
                 new google.maps.LatLng(@queryParams.lat, @queryParams.lng)
               else if @currentCollection()?.position()
                 @currentCollection().position()
               else
                 i = 0
                 i++ until i >= @collections().length || @collections()[i].position()
                 if i < @collections().length
                    @collections()[i].position()
                 else
                    new google.maps.LatLng(10, 90)
      zoom = if @queryParams.z then parseInt(@queryParams.z) else 4

      mapOptions =
        center: center
        zoom: zoom
        mapTypeId: google.maps.MapTypeId.ROADMAP
        scaleControl: true
      @map = new google.maps.Map document.getElementById("map"), mapOptions

      # Create a dummy overlay to easily get a position of a marker in pixels
      # See the second answer in http://stackoverflow.com/questions/2674392/how-to-access-google-maps-api-v3-markers-div-and-its-pixel-position
      @map.dummyOverlay = new google.maps.OverlayView()
      @map.dummyOverlay.draw = ->
      @map.dummyOverlay.setMap @map

      listener = google.maps.event.addListener @map, 'bounds_changed', =>
        google.maps.event.removeListener listener
        @reloadMapSites()
        @rewriteUrl()

      google.maps.event.addListener @map, 'dragend', =>
        @reloadMapSites()
        @rewriteUrl()

      google.maps.event.addListener @map, 'zoom_changed', =>
        listener2 = google.maps.event.addListener @map, 'bounds_changed', =>
          google.maps.event.removeListener listener2
          @reloadMapSites() if @reloadMapSitesAutomatically
          @rewriteUrl()

      true

    @showMap: (callback) ->
      if @showingMap()
        if callback && typeof(callback) == 'function'
          callback()
        return

      @markers = {}
      @clusters = {}
      @alertMarkers   = {}
      @showingMap(true)

      # This fixes problems when changing from fullscreen expanded to table view and then going back to map view
      if @fullscreen()
        @fullscreenExpanded(false)
        $('.expand-collapse_button').show()
        $(".expand-collapse_button").addClass("oleftcollapse")
        $(".expand-collapse_button").removeClass("oleftexpand")


      showMap = =>
        if $('#map').length == 0
          setTimeout(showMap, 10)
        else
          @initMap()
          if callback && typeof(callback) == 'function'
            callback()
      setTimeout(showMap, 10)
      setTimeout(window.adjustContainerSize, 10)

    @reloadMapSites: (callback) ->
      return unless @map

      bounds = @map.getBounds()

      # Wait until map is loaded
      unless bounds
        setTimeout(( => @reloadMapSites(callback)), 100)
        return

      collection_ids = if @currentCollection()
                         [@currentCollection().id]
                       else
                          c.id for c in @collections() when c.checked()

      zoom = @map.getZoom()
      query = @generateQueryParams(bounds, collection_ids, zoom)

      @mapRequestNumber += 1
      currentMapRequestNumber = @mapRequestNumber

      getCallback = (data = {}) =>
        return unless currentMapRequestNumber == @mapRequestNumber
        if @showingMap()
          @drawSitesInMap data.sites
          @drawClustersInMap data.clusters
          # Original position for sites in identical location.
          # commented out 
          #@drawOriginalGhost data.original_ghost
          @reloadMapSitesAutomatically = true
          @adjustZIndexes()
          @updateSitesCount()
          @notifySitesChanged()

        callback() if callback && typeof(callback) == 'function'

      if query.collection_ids.length == 0
        # Save a request to the server if there are no selected collections
        getCallback()
      else
        $.get "/sites/search.json", query, getCallback

    @generateQueryParams: (bounds, collection_ids, zoom) ->
      ne = bounds.getNorthEast()
      sw = bounds.getSouthWest()

      query =
        n: ne.lat()
        s: sw.lat()
        e: ne.lng()
        w: sw.lng()
        z: zoom
        collection_ids: collection_ids

      query.selected_hierarchies = @selectedHierarchy().hierarchyIds() if @selectedHierarchy()
      query.hierarchy_code = window.model.groupBy().esCode if @selectedHierarchy() && window.model.groupBy().esCode

      query.exclude_id = @selectedSite().id() if @selectedSite()?.id()
      query.search = @lastSearch() if @lastSearch()

      filter.setQueryParams(query) for filter in @filters()

      query

    @onSitesChanged: (listener) ->
      @sitesChangedListeners.push listener

    @notifySitesChanged: ->
      for listener in @sitesChangedListeners
        listener()

    @drawOriginalGhost: (ghosts = []) ->
      for ghost in ghosts
         markerOptions =
           map: @map
           position: new google.maps.LatLng(ghost.lat, ghost.lng)
           zIndex: @zIndex(ghost.lat)
           optimized: false
           icon: @markerImageInactive
           shadow: @markerImageInactiveShadow
        newMarker = new google.maps.Marker markerOptions

    @drawSitesInMap: (sites = []) ->
      dataSiteIds = {}
      editing = window.model.editingSiteLocation()
      selectedSiteId = @selectedSite()?.id()
      oldSelectedSiteId = @oldSelectedSite?.id() # Optimization to prevent flickering

      # Add markers if they are not already on the map
       
      for site in sites
        dataSiteIds[site.id] = site.id
        if site.alert == 'true'
          if @alertMarkers[site.id]
            if site.highlighted
              @alertMarkers[site.id].setTarget() 
          else
            if site.id == oldSelectedSiteId
              @alertMarkers[site.id] = @oldSelectedSite.alertMarker
              @alertMarkers[site.id].site = site
              @alertMarkers[site.id].setActive()
              @oldSelectedSite.deleteAlertMarker false
              delete @oldSelectedSite
            else
              @createAlert(site)
            localId = @alertMarkers[site.id].siteId = site.id
            @alertMarkers[localId].setupListeners()
        else
          if @markers[site.id]
            if site.highlighted
              @setMarkerIcon @markers[site.id], 'target'
            else
              #@setMarkerIcon @markers[site.id], (@editingSite() ? 'inactive' : 'active')

          else
            if site.id == oldSelectedSiteId
              @markers[site.id] = @oldSelectedSite.marker
              @markers[site.id].site = site
              @deleteMarkerListeners site.id
              @setMarkerIcon @markers[site.id], 'active'
              @oldSelectedSite.deleteMarker false
              delete @oldSelectedSite
            else
              # commented out 
              # position = new google.maps.LatLng(site.lat, site.lng)
              # if site.ghost_radius?
              #   projection = @map.dummyOverlay.getProjection()
              #   pointInPixels = projection.fromLatLngToContainerPixel(position)
              #   pointInPixels.x += 25 * Math.cos(site.ghost_radius)
              #   pointInPixels.y += 25 * Math.sin(site.ghost_radius)
              #   position = projection.fromContainerPixelToLatLng(pointInPixels)

              markerOptions =
                map: @map
                position: new google.maps.LatLng(site.lat, site.lng)
                zIndex: @zIndex(site.lat)
                optimized: false

              # Show site in grey if editing a site (but not if it's the one being edited)
              if editing
                markerOptions.icon = @markerImage 'resmap_' + site.icon + '_inactive.png'
                #markerOptions.shadow = @markerImageInactiveShadow
              else if (selectedSiteId && selectedSiteId == site.id)
                markerOptions.icon = @markerImage 'resmap_' + site.icon + '_target.png'
                #markerOptions.shadow = @markerImageTargetShadow

              newMarker = new google.maps.Marker markerOptions
              newMarker.name = site.name
              newMarker.site = site
              @setMarkerIcon newMarker, 'active'
              newMarker.collectionId = site.collection_id

              @markers[site.id] = newMarker
            localId = @markers[site.id].siteId = site.id
            do (localId) => @setupMarkerListeners @markers[localId], localId

      # Determine which markers need to be removed from the map
      toRemove = []
      for siteId, marker of @markers
        toRemove.push siteId unless dataSiteIds[siteId]

      # And remove them
      for siteId in toRemove
        @deleteMarker siteId

      toRemoveAlert = []
      for siteId, alert of @alertMarkers
        toRemoveAlert.push siteId unless dataSiteIds[siteId]

      for siteId in toRemoveAlert
        @deleteAlert siteId, true
      if @oldSelectedSite
        if @oldSelectedSite.id() != selectedSiteId
          if @oldSelectedSite.alert() 
            @oldSelectedSite.deleteAlertMarker()
          else
            @oldSelectedSite.deleteMarker()         
          delete @oldSelectedSite

    @setupMarkerListeners: (marker, localId) ->
      marker.clickListener = google.maps.event.addListener marker, 'click', (event) =>
        @setMarkerIcon marker, 'target'
        @editSiteFromMarker localId, marker.collectionId

      # Create a popup and position it in the top center. To do so we need to add it to the document,
      # get its width and reposition accordingly.
      marker.mouseOverListener = google.maps.event.addListener marker, 'mouseover', (event) =>
        pos = window.model.map.dummyOverlay.getProjection().fromLatLngToContainerPixel marker.getPosition()
        offset = $('#map').offset()
        marker.popup = $("<div style=\"position:absolute;top:#{offset.top + pos.y - 64}px;left:#{offset.left + pos.x}px;padding:4px;background-color:black;color:white;border:1px solid grey\">#{marker.name}</div>")
        $(document.body).append(marker.popup)
        offset = $(marker.popup).offset()
        offset.left -= $(marker.popup).width() / 2
        $(marker.popup).offset(offset)
      marker.mouseOutListener = google.maps.event.addListener marker, 'mouseout', (event) =>
        marker.popup.remove()
    
    @drawClustersInMap: (clusters = []) ->
      dataClusterIds = {}
      editing = window.model.editingSiteLocation()

      # Add clusters if they are not already on the map
      for cluster in clusters
        dataClusterIds[cluster.id] = cluster.id
        currentCluster = @clusters[cluster.id]
        if currentCluster
          currentCluster.setData(cluster, false)
        else
          currentCluster = @createCluster(cluster)
        currentCluster.setInactive() if editing

      # Determine which clusters need to be removed from the map
      toRemove = []
      for clusterId, cluster of @clusters
        toRemove.push clusterId unless dataClusterIds[clusterId]

      # And remove them
      @deleteCluster clusterId for clusterId in toRemove

    @setAllMarkersInactive: ->
      editingSiteId = @editingSite()?.id()?.toString()
      for siteId, marker of @markers
        @setMarkerIcon marker, (if editingSiteId == siteId then 'target' else 'inactive')
      for siteId, marker of @alertMarkers
        if editingSiteId == siteId
          marker.setTarget()
        else
          marker.setInactive()
      for clusterId, cluster of @clusters
        cluster.setInactive()

    @setAllMarkersActive: ->
      selectedSiteId = @selectedSite()?.id()?.toString()
      for siteId, marker of @markers
        if selectedSiteId == siteId
          @setMarkerIcon marker, 'target'
        else
          @setMarkerIcon marker, 'active'
      for siteId, marker of @alertMarkers
        if selectedSiteId == siteId
          marker.setTarget()
        else
          marker.setActive()

      for clusterId, cluster of @clusters
        cluster.setActive()

    @setMarkerIcon: (marker, icon) ->
      switch icon
        
        when 'active', 'null'
          if marker.site && marker.site.icon != 'null'
            # temporary comment this line, will change soon
            #marker.setIcon null
            marker.setIcon @markerImage 'resmap_' + marker.site.icon + '.png'
          else
            maker.setIcon null
            marker.setShadow null
            #marker.setIcon @markerImageActive
            #marker.setShadow @markerImageActiveShadow
        when 'inactive'
          marker.setIcon @markerImage 'resmap_' + marker.site.icon + '_inactive.png'
          #marker.setShadow @markerImageInactiveShadow
        when 'target'
          # marker target or focus 
          marker.setIcon @markerImage 'resmap_' + marker.site.icon + '_target.png'
          #marker.setShadow @markerImageTargetShadow


    @deleteMarker: (siteId, removeFromMap = true) ->
      return unless @markers[siteId]
      @markers[siteId].setMap null if removeFromMap
      # commented out  
      #@markers[siteId].popup.remove() if @markers[siteId].popup
      @deleteMarkerListeners siteId
      delete @markers[siteId]

    @deleteMarkerListeners: (siteId) ->
      for listener in ['click', 'mouseOver', 'mouseOut']
        if @markers[siteId]["#{listener}Listener"]
          google.maps.event.removeListener @markers[siteId]["#{listener}Listener"]
          delete @markers[siteId]["#{listener}Listener"]

    @deleteAlertMarkerListeners: (siteId) ->
      for listener in ['divDown', 'divUp']
        if @alertMarkers[siteId]["#{listener}Listener"]
          google.maps.event.removeListener @alertMarkers[siteId]["#{listener}Listener"]
          delete @alertMarkers[siteId]["#{listener}Listener"]

    @setupAlertMarkerListeners: (alertMarker, siteId) ->
      alertMarker.divDownListener = google.maps.event.addDomListener alertMarker.divDownListener, 'mousedown', (event) =>
        @editSiteFromMarker localId, marker.collectionId

    @createCluster: (cluster) ->
      @clusters[cluster.id] = new Cluster @map, cluster

    @createAlert: (alert) ->
      @alertMarkers[alert.id] = new Alert @map, alert

    @deleteCluster: (id) ->
      @clusters[id].setMap null
      delete @clusters[id]
    
    @deleteAlert: (id, removeFromMap = true) ->
      return unless @alertMarkers[id] 
      @alertMarkers[id].setMap null if removeFromMap
      @deleteAlertMarkerListeners id 
      delete @alertMarkers[id]

    @zIndex: (lat) ->
      bounds = @map.getBounds()
      north = bounds.getNorthEast().lat()
      south = bounds.getSouthWest().lat()
      total = north - south
      current = lat - south
      -Math.round(current * 1000000 / total)

    @adjustZIndexes: ->
      for siteId, marker of @markers
        marker.setZIndex(@zIndex(marker.getPosition().lat()))
      for clusterId, cluster of @clusters
        cluster.adjustZIndex()
      for alertId, alert of @alertMarkers
        alert.adjustZIndex()

    @updateSitesCount: ->
      count = 0
      bounds = @map.getBounds()
      for siteId, marker of @markers
        if bounds.contains marker.getPosition()
          count += 1
      for clusterId, cluster of @clusters
        if bounds.contains cluster.position
          count += cluster.count
      count += 1 if @selectedSite()
      @sitesCount count

    @showTable: ->
      @queryParams = $.url().param()
      @sortByName()
      @exitSite() if @editingSite()
      @editingSite(null)
      @oldSelectedSite = null
      delete @markers
      delete @clusters
      delete @map
      @showingMap(false)
      @refreshTimeago()
      @makeFixedHeaderTable()
      setTimeout(window.adjustContainerSize, 10)

    @makeFixedHeaderTable: ->
      unless @showingMap()
        oldScrollLeft = $('.tablescroll').scrollLeft()

        $('table.GralTable').fixedHeaderTable 'destroy'
        $('table.GralTable').fixedHeaderTable footer: false, cloneHeadToFoot: false, themeClass: 'GralTable'

        width = $('.fht-tbody table').width()
        $('.fht-thead table').width(width)
        $('.fht-thead table').css('table-layout', 'fixed')

        $col = $('.fht-tbody colgroup').clone()
        $('.fht-thead table').prepend($col)
        $('.fht-tbody table').css('table-layout', 'fixed')

        setTimeout((->
          $('.tablescroll').scrollLeft oldScrollLeft
          window.adjustContainerSize()
        ), 20)

    @markerImage: (icon) ->
      new google.maps.MarkerImage(
        @iconUrl(icon), new google.maps.Size(32, 37), new google.maps.Point(0, 0), new google.maps.Point(16, 37)
      )

    @markerImageShadow: (icon) ->
      new google.maps.MarkerImage(
        @iconUrl(icon), new google.maps.Size(37, 34), new google.maps.Point(20, 0), new google.maps.Point(10, 34)
      )

    @iconUrl: (icon) -> icon.url ? "/assets/#{icon}"

    @initInsteddPlatform:  ->
      $.instedd.init_components() if $.instedd

    @initAutocomplete: (callback) ->
      @initInsteddPlatform()
      source = []
      for key, value of @siteIds
        item = id: key, label: value.name(), value: value.name()
        source.push(item)
      $(".autocomplete-site-input").autocomplete
        source: source
        select: (event, ui) ->
          # TODO: Complete this feature.
          $(event.target).val(ui.item.value)
          $(event.target).change()


    @initDatePicker: (callback) ->
      @initInsteddPlatform()

      options = {}
      options.onSelect = callback if callback
      # fix dinamic DOM
      # http://stackoverflow.com/questions/1059107/why-does-jquery-uis-datepicker-break-with-a-dynamic-dom
      $(".ux-datepicker").removeClass('hasDatepicker').datepicker(options)

