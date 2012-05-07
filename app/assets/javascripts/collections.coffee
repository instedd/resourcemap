@initCollections = ->
  class CollectionViewModel
    constructor: (collections) ->
      @collections = ko.observableArray $.map(collections, (x) -> new Collection(x))
      @currentCollection = ko.observable()
      @currentParent = ko.observable()
      @editingSite = ko.observable()
      @selectedSite = ko.observable()
      @parentSite = ko.computed =>
        if @selectedSite()
          if @selectedSite().group() then @selectedSite() else @selectedSite().parent
        else
          null
      @loadingSite = ko.observable(false)
      @newOrEditSite = ko.computed => if @editingSite() && !@editingSite().group() && (!@editingSite().id() || @editingSite().inEditMode()) then @editingSite() else null
      @newGroup = ko.computed => if @editingSite() && !@editingSite().id() && @editingSite().group() then @editingSite() else null
      @showSite = ko.computed => if @editingSite()?.id() && !@editingSite().group() && !@editingSite().inEditMode() then @editingSite() else null
      @showGroup = ko.computed => if @editingSite()?.id() && @editingSite().group() then @editingSite() else null
      @showingMap = ko.observable(true)
      @sitesCount = ko.observable(0)
      @sitesCountText = ko.computed => if @sitesCount() == 1 then '1 site on map' else "#{@sitesCount()} sites on map"
      @markers = {}
      @clusters = {}
      @siteIds = {}
      @reloadMapSitesAutomatically = true
      @requestNumber = 0
      @geocoder = new google.maps.Geocoder();
      @search = ko.observable('')
      @lastSearch = ko.observable(null)
      @showingRefinePopup = ko.observable(false)
      @expandedRefineProperty = ko.observable()
      @expandedRefinePropertyOperator = ko.observable()
      @expandedRefinePropertyValue = ko.observable()
      @filters = ko.observableArray([])
      @sort = ko.observable()
      @sortDirection = ko.observable()

      @filters.subscribe => @performSearch()

      # To be used for form actions, so the url doesn't change
      @formAction = ko.computed => "##{if @currentCollection() then @currentCollection().id() else ''}"

      @markerImageInactive = new google.maps.MarkerImage(
        "/assets/marker_inactive.png", new google.maps.Size(20, 34), new google.maps.Point(0, 0), new google.maps.Point(10, 34)
      )
      @markerImageInactiveShadow = new google.maps.MarkerImage(
        "/assets/marker_inactive.png", new google.maps.Size(37, 34), new google.maps.Point(20, 0), new google.maps.Point(10, 34)
      )
      @markerImageTarget = new google.maps.MarkerImage(
        "/assets/marker_target.png", new google.maps.Size(20, 34), new google.maps.Point(0, 0), new google.maps.Point(10, 34)
      )
      @markerImageTargetShadow = new google.maps.MarkerImage(
        "/assets/marker_target.png", new google.maps.Size(37, 34), new google.maps.Point(20, 0), new google.maps.Point(10, 34)
      )

      location.hash = '#/' unless location.hash

      $.each @collections(), (idx) =>
        @collections()[idx].checked.subscribe (newValue) =>
          @reloadMapSites()

    initSammy: =>
      self = this

      Sammy( ->
        @get '#:collection', ->
          # We don't want to fetch the collection if there's a search
          return if $.trim(self.search()).length > 0

          collection = self.findCollectionById parseInt(this.params.collection)
          self.currentCollection collection
          self.unselectSite() if self.selectedSite()
          collection.loadMoreSites() if collection.sitesPage == 1

          initialized = self.initMap()
          collection.panToPosition(true) unless initialized

          collection.fetchFields =>
            self.refreshTimeago()
            self.makeFixedHeaderTable()
        @get '#/', ->
          self.currentCollection(null)
          self.unselectSite() if self.selectedSite()
          self.search('')
          self.filters([])
          self.sort(null)
          self.sortDirection(null)

          initialized = self.initMap()
          self.reloadMapSites() unless initialized
          self.refreshTimeago()
          self.makeFixedHeaderTable()
      ).run()

    showMap: (callback) =>
      if @showingMap()
        if callback && typeof(callback) == 'function'
          callback()
        return

      @markers = {}
      @clusters = {}
      @showingMap(true)
      showMap = =>
        if $('#map').length == 0
          setTimeout(showMap, 10)
        else
          @initMap()
          if callback && typeof(callback) == 'function'
            callback()
      setTimeout(showMap, 10)
      setTimeout(window.adjustContainerSize 10)

    showTable: =>
      delete @markers
      delete @clusters
      delete @map
      @selectedSite().deleteMarker() if @selectedSite()
      @exitSite() if @editingSite()
      @showingMap(false)
      @refreshTimeago()
      @makeFixedHeaderTable()
      setTimeout(window.adjustContainerSize 10)

    findCollectionById: (id) => (x for x in @collections() when x.id() == id)[0]

    goToRoot: -> location.hash = '/'

    enterCollection: (collection) -> location.hash = "#{collection.id()}"

    editCollection: (collection) -> window.location = "/collections/#{collection.id()}"

    createCollection: -> window.location = "/collections/new"

    createGroup: => @createSiteOrGroup true

    createSite: => @createSiteOrGroup false

    createSiteOrGroup: (group) =>
      @goBackToTable = true unless @showingMap()
      @showMap =>
        parent = @parentSite() || @currentCollection()
        parentId = if !@parentSite() || @parentSite().level() == 0 then null else @parentSite().id()
        pos = @originalSiteLocation = @map.getCenter()
        site = if group
                 new Site(parent, parent_id: parentId, lat: pos.lat(), lng: pos.lng(), group: group, location_mode: 'auto')
               else
                 new Site(parent, parent_id: parentId, lat: pos.lat(), lng: pos.lng(), group: group)
        site.copyPropertiesToCollection(@currentCollection()) unless site.group()
        @editingSite site
        @editingSite().startEditLocationInMap()

    editSite: (site) =>
      @goBackToTable = true unless @showingMap()
      @showMap =>
        site.copyPropertiesToCollection(site.parentCollection())
        if @selectedSite() && @selectedSite().id() == site.id()
          @unselectSite()
          @selectSite(site)
        else
          @selectSite(site)
        @editingSite(site)

    editSiteFromMarker: (siteId) =>
      site = @siteIds[siteId]
      if site
        @editSite site
      else
        @loadingSite(true)
        if @selectedSite() && @selectedSite().marker
          @setMarkerIcon @selectedSite().marker, 'active'
        $.get "/sites/#{siteId}.json", {}, (data) =>
          @loadingSite(false)
          parent = window.model.findCollectionById(data.collection_id)
          site = new Site(parent, data)
          @editSite site

    saveSite: =>
      return unless @editingSite().valid()

      callback = (data) =>
        unless @editingSite().id()
          @editingSite().id(data.id)
          @editingSite().parent.addSite(@editingSite())

        @editingSite().updatedAt(data.updated_at)

        @editingSite().position(data)
        @editingSite().parent.fetchLocation()

        if @editingSite().inEditMode()
          @editingSite().exitEditMode(true)
        else
          @editingSite().deleteMarker()
          @selectedSite(@editingSite().parent) if @editingSite().parentId()
          @exitSite()

      unless @editingSite().group()
        @editingSite().copyPropertiesFromCollection(@currentCollection())

      @editingSite().post @editingSite().toJSON(), callback

    exitSite: =>
      if @editingSite().inEditMode()
        @editingSite().exitEditMode()
        return

      # Unselect site if it's not on the tree
      oldParentSite = @parentSite()
      @unselectSite() unless @siteIds[@editingSite().id()]
      @selectedSite(oldParentSite) if !@selectedSite() && oldParentSite && oldParentSite.level() != 0
      @editingSite().unsubscribeToLocationModeChange()
      @editingSite().editingLocation(false)
      @editingSite().deleteMarker() unless @editingSite().id()
      @editingSite(null)
      window.model.setAllMarkersActive()
      if @goBackToTable
        @showTable()
        delete @goBackToTable

    deleteSite: =>
      if confirm("Are you sure you want to delete #{@editingSite().name()}?")
        @unselectSite()
        @editingSite().parent.removeSite(@editingSite())
        $.post "/sites/#{@editingSite().id()}", {_method: 'delete'}, =>
          @editingSite().parent.fetchLocation()
          @editingSite().deleteMarker()
          @exitSite()
          @reloadMapSites() if @showingMap()

    selectSite: (site) =>
      if @showingMap()
        if @selectedSite()
          if @selectedSite().group()
            @setAllMarkersActive()
          else if @selectedSite().marker
            # This is to prevent flicker: when the map reloads, we try to reuse the old site marker
            if site.group()
              @selectedSite().deleteMarker()
            else
              @oldSelectedSite = @selectedSite()
              @setMarkerIcon @selectedSite().marker, 'active'
              @selectedSite().marker.setZIndex(@zIndex(@selectedSite().marker.getPosition().lat()))
          @selectedSite().selected(false)

        if @selectedSite() == site
          @selectedSite(null)
          @reloadMapSites()
        else
          @selectedSite(site)
          @selectedSite().selected(true)
          if @selectedSite().group()
            @setGroupTargetMarkers()
          if @selectedSite().id() && @selectedSite().hasLocation()
            # Again, all these checks are to prevent flickering
            if @markers[@selectedSite().id()]
              @selectedSite().marker = @markers[@selectedSite().id()]
              @selectedSite().marker.setZIndex(200000)
              @setMarkerIcon @selectedSite().marker, 'target'
              @deleteMarker @selectedSite().id(), false
            else
              @selectedSite().createMarker() unless @selectedSite().group()
            @selectedSite().panToPosition()
          else if @oldSelectedSite
            @oldSelectedSite.deleteMarker()
            delete @oldSelectedSite
            @reloadMapSites()

      else
        @selectedSite().selected(false) if @selectedSite()
        if @selectedSite() == site
          @selectedSite(null)
        else
          @selectedSite(site)

    unselectSite: =>
      @selectSite(@selectedSite()) if @selectedSite()

    toggleSite: (site) =>
      site.toggle()

    initMap: =>
      return true unless @showingMap()
      return false if @map

      center = if @currentCollection()?.position()
                 @currentCollection().position()
               else if @collections().length > 0 && @collections()[0].position()
                 @collections()[0].position()
               else
                 new google.maps.LatLng(10, 90)

      mapOptions =
        center: center
        zoom: 4
        mapTypeId: google.maps.MapTypeId.ROADMAP
        scaleControl: true
      @map = new google.maps.Map document.getElementById("map"), mapOptions

      listener = google.maps.event.addListener @map, 'bounds_changed', =>
        google.maps.event.removeListener listener
        @reloadMapSites()

      google.maps.event.addListener @map, 'dragend', => @reloadMapSites()
      google.maps.event.addListener @map, 'zoom_changed', =>
        listener2 = google.maps.event.addListener @map, 'bounds_changed', =>
          google.maps.event.removeListener listener2
          @reloadMapSites() if @reloadMapSitesAutomatically

      true

    reloadMapSites: (callback) =>
      bounds = @map.getBounds()

      # Wait until map is loaded
      unless bounds
        setTimeout(( => @reloadMapSites(callback)), 100)
        return

      ne = bounds.getNorthEast()
      sw = bounds.getSouthWest()
      collection_ids = if @currentCollection()
                         [@currentCollection().id()]
                       else
                          c.id for c in @collections() when c.checked()
      query =
        n: ne.lat()
        s: sw.lat()
        e: ne.lng()
        w: sw.lng()
        z: @map.getZoom()
        collection_ids: collection_ids
      query.exclude_id = @selectedSite().id() if @selectedSite()?.id() && !@selectedSite().group()
      query.search = @lastSearch() if @lastSearch()

      filter.setQueryParams(query) for filter in @filters()

      @requestNumber += 1
      currentRequestNumber = @requestNumber

      getCallback = (data = {}) =>
        return unless currentRequestNumber == @requestNumber

        if @showingMap()
          @drawSitesInMap data.sites
          @drawClustersInMap data.clusters
          @reloadMapSitesAutomatically = true
          @adjustZIndexes()
          @updateSitesCount()

        callback() if callback && typeof(callback) == 'function'

      if query.collection_ids.length == 0
        # Save a request to the server if there are no selected collections
        getCallback()
      else
        $.get "/sites/search.json", query, getCallback

    drawSitesInMap: (sites = []) =>
      dataSiteIds = {}
      editingSiteId = if @editingSite()?.id() && (@editingSite().editingLocation() || @editingSite().inEditMode()) then @editingSite().id() else null
      selectedSiteId = @selectedSite()?.id()
      selectedGroupId = if @selectedSite()?.group() && @selectedSite()?.id() then @selectedSite().id() else null
      oldSelectedSiteId = @oldSelectedSite?.id() # Optimization to prevent flickering

      # Add markers if they are not already on the map
      for site in sites
        dataSiteIds[site.id] = site.id
        unless @markers[site.id]
          if site.id == oldSelectedSiteId
            @markers[site.id] = @oldSelectedSite.marker
            @deleteMarkerListener site.id
            @setMarkerIcon @markers[site.id], 'active'
            @oldSelectedSite.deleteMarker false
            delete @oldSelectedSite
          else
            markerOptions =
              map: @map
              position: new google.maps.LatLng(site.lat, site.lng)
              zIndex: @zIndex(site.lat)
              optimized: false

            # Show site in grey if editing a site (but not if it's the one being edited)
            if editingSiteId && editingSiteId != site.id
              markerOptions.icon = @markerImageInactive
              markerOptions.shadow = @markerImageInactiveShadow
            if (selectedSiteId && selectedSiteId == site.id) || (selectedGroupId && site.parent_ids && site.parent_ids.indexOf(selectedGroupId) >= 0)
              markerOptions.icon = @markerImageTarget
              markerOptions.shadow = @markerImageTargetShadow
            @markers[site.id] = new google.maps.Marker markerOptions
            @markers[site.id].parentIds = site.parent_ids
          localId = @markers[site.id].siteId = site.id
          do (localId) =>
            @markers[localId].listener = google.maps.event.addListener @markers[localId], 'click', (event) =>
              @setMarkerIcon @markers[localId], 'target'
              @editSiteFromMarker localId

      # Determine which markers need to be removed from the map
      toRemove = []
      for siteId, marker of @markers
        toRemove.push siteId unless dataSiteIds[siteId]

      # And remove them
      for siteId in toRemove
        @deleteMarker siteId

      if @oldSelectedSite
        @oldSelectedSite.deleteMarker() if @oldSelectedSite.id() != selectedSiteId
        delete @oldSelectedSite

    drawClustersInMap: (clusters = []) =>
      selectedGroupId = if @selectedSite()?.group() && @selectedSite()?.id() then @selectedSite().id() else null

      dataClusterIds = {}

      # Add clusters if they are not already on the map
      for cluster in clusters
        dataClusterIds[cluster.id] = cluster.id
        currentCluster = @clusters[cluster.id]
        if currentCluster
          currentCluster.setData(cluster)
        else
          currentCluster = @createCluster(cluster)
        if (selectedGroupId && cluster.parent_ids && cluster.parent_ids.indexOf(selectedGroupId) >= 0)
          currentCluster.setTarget()

      # Determine which clusters need to be removed from the map
      toRemove = []
      for clusterId, cluster of @clusters
        toRemove.push clusterId unless dataClusterIds[clusterId]

      # And remove them
      @deleteCluster clusterId for clusterId in toRemove

    setAllMarkersInactive: =>
      editingSiteId = @editingSite()?.id()?.toString()
      for siteId, marker of @markers
        @setMarkerIcon marker, (if editingSiteId == siteId then 'target' else 'inactive')
      for clusterId, cluster of @clusters
        cluster.setInactive()

    setAllMarkersActive: =>
      selectedSiteId = @selectedSite()?.id()?.toString()
      for siteId, marker of @markers
        @setMarkerIcon marker, (if selectedSiteId == siteId then 'target' else 'active')
      for clusterId, cluster of @clusters
        cluster.setActive()

    setGroupTargetMarkers: =>
      id = @selectedSite().id()
      for siteId, marker of @markers when marker.parentIds && marker.parentIds.indexOf(id) >= 0
        @setMarkerIcon marker, 'target'
      for clusterId, cluster of @clusters when cluster.parentIds && cluster.parentIds.indexOf(id) >= 0
        cluster.setTarget()

    setMarkerIcon: (marker, icon) =>
      switch icon
        when 'active'
          marker.setIcon null
          marker.setShadow null
        when 'inactive'
          marker.setIcon @markerImageInactive
          marker.setShadow @markerImageInactiveShadow
        when 'target'
          marker.setIcon @markerImageTarget
          marker.setShadow @markerImageTargetShadow

    deleteMarker: (siteId, removeFromMap = true) =>
      return unless @markers[siteId]
      @markers[siteId].setMap null if removeFromMap
      @deleteMarkerListener siteId
      delete @markers[siteId]

    deleteMarkerListener: (siteId) =>
      if @markers[siteId].listener
        google.maps.event.removeListener @markers[siteId].listener
        delete @markers[siteId].listener

    createCluster: (cluster) =>
      @clusters[cluster.id] = new Cluster @map, cluster

    deleteCluster: (id) =>
      @clusters[id].setMap null
      delete @clusters[id]

    zIndex: (lat) =>
      bounds = @map.getBounds()
      north = bounds.getNorthEast().lat()
      south = bounds.getSouthWest().lat()
      total = north - south
      current = lat - south
      -Math.round(current * 100000 / total)

    adjustZIndexes: =>
      for siteId, marker of @markers
        marker.setZIndex(@zIndex(marker.getPosition().lat()))
      for clusterId, cluster of @clusters
        cluster.adjustZIndex()

    updateSitesCount: =>
      count = 0
      bounds = @map.getBounds()
      for siteId, marker of @markers
        count += 1 if bounds.contains marker.getPosition()
      for clusterId, cluster of @clusters
        count += cluster.count if bounds.contains cluster.position
      count += 1 if @selectedSite()
      @sitesCount count

    showPopupWithMaxValueOfProperty: (field, event) =>
      # Create a popup that first says "Loading...", then loads the content via ajax.
      # The popup is removed when on mouse out.
      offset = $(event.target).offset()
      element = $("<div id=\"thepopup\" style=\"position:absolute;top:#{offset.top - 30}px;left:#{offset.left}px;padding:4px;background-color:black;color:white;border:1px solid grey\">Loading maximum value...</div>")
      $(document.body).append(element)
      mouseoutHandler = ->
        element.remove()
        $(event.target).unbind 'mouseout', mouseoutHandler
      event = $(event.target).bind 'mouseout', mouseoutHandler
      $.get "/collections/#{@currentCollection().id()}/max_value_of_property.json", {property: field.code()}, (data) =>
        element.text "Maximum #{field.name()}: #{data}"

    refreshTimeago: -> $('.timeago').timeago()

    makeFixedHeaderTable: ->
      unless @showingMap()
        oldScrollLeft = $('.tablescroll').scrollLeft()

        $('table.GralTable').fixedHeaderTable 'destroy'
        $('table.GralTable').fixedHeaderTable footer: false, cloneHeadToFoot: false, themeClass: 'GralTable'

        setTimeout((->
          $('.tablescroll').scrollLeft oldScrollLeft
          window.adjustContainerSize()
        ), 20)

    performSearch: =>
      return false unless @currentCollection()

      rootCollection = @currentCollection().collection ? @currentCollection()

      @unselectSite()
      if $.trim(@search()).length == 0 && @filters().length == 0 && !@sort()
        @currentCollection(rootCollection)
        @lastSearch(null)
      else
        @currentCollection(new CollectionSearch(rootCollection, @search(), @filters(), @sort(), @sortDirection()))
        @currentCollection().loadMoreSites()
        @lastSearch(@search())
      if @showingMap()
        @reloadMapSites()
      else
        window.adjustContainerSize()
      false

    clearSearch: =>
      @search('')
      @performSearch()

    highlightSearch: (text) =>
      if @lastSearch()
        text = "#{text}"
        idx = text.toLowerCase().indexOf(@lastSearch().toLowerCase())
        if idx >= 0
          "#{text.substring(0, idx)}<b class=\"highlight\">#{text.substring(idx, idx + @lastSearch().length)}</b>#{text.substring(idx + @lastSearch().length)}"
        else
          text
      else
        text

    toggleRefinePopup: =>
      @showingRefinePopup(!@showingRefinePopup())
      if @showingRefinePopup()
        $refine = $('#refine')
        refineOffset = $refine.offset()
        $('#refine-popup').offset(top: refineOffset.top + $refine.outerHeight(), left: refineOffset.left)
      else
        @expandedRefineProperty(null)
        @expandedRefinePropertyOperator('=')
        @expandedRefinePropertyValue('')

    toggleRefineProperty: (property) =>
      @expandedRefinePropertyOperator('=')
      @expandedRefinePropertyValue('')
      if @expandedRefineProperty() == property
        @expandedRefineProperty(null)
      else
        @expandedRefineProperty(null) # Needed because sometimes we get a stack overflow (can't find the reason to it)
        @expandedRefineProperty(property)

    filterDescription: (filter) =>
      if @filters()[0] == filter
        "Show sites #{filter.description()}"
      else
        filter.description()

    removeFilter: (filter) =>
      @filters.remove filter

    filterByLastHour: =>
      @filters.push(new FilterByLastHour())
      @toggleRefinePopup()

    filterByLastDay: =>
      @filters.push(new FilterByLastDay())
      @toggleRefinePopup()

    filterByLastWeek: =>
      @filters.push(new FilterByLastWeek())
      @toggleRefinePopup()

    filterByLastMonth: =>
      @filters.push(new FilterByLastMonth())
      @toggleRefinePopup()

    filterByProperty: =>
      return if $.trim(@expandedRefinePropertyValue()).length == 0

      field = @currentCollection().findFieldByCode @expandedRefineProperty()
      if field.kind() == 'text'
        @filters.push(new FilterByTextProperty(field.code(), field.name(), @expandedRefinePropertyValue()))
      else if field.kind() == 'numeric'
        @filters.push(new FilterByNumericProperty(field.code(), field.name(), @expandedRefinePropertyOperator(), @expandedRefinePropertyValue()))
      else if field.kind() == 'select_one' || field.kind() == 'select_many'
        valueLabel = (option for option in field.options() when option.code() == @expandedRefinePropertyValue())[0].label()
        @filters.push(new FilterBySelectProperty(field.code(), field.name(), @expandedRefinePropertyValue(), valueLabel))

      @toggleRefinePopup()

    expandedRefinePropertyValueKeyPress: (model, event) =>
      switch event.keyCode
        when 13 then @filterByProperty()
        else true

    sortBy: (field) =>
      @sortByCode(field.code())

    sortByName: =>
      @sortByCode('name')

    sortByDate: =>
      @sortByCode('updated_at', false)

    sortByCode: (code, defaultOrder = true) =>
      if @sort() == code
        if @sortDirection() == defaultOrder
          @sortDirection(!defaultOrder)
        else
          @sort(null)
          @sortDirection(null)
      else
        @sort(code)
        @sortDirection(defaultOrder)
      @performSearch()
      @makeFixedHeaderTable()

    exportInRSS: => window.open @currentCollection().link('rss')
    exportInJSON: => window.open @currentCollection().link('json')
    exportInCSV: => window.location = @currentCollection().link('csv')

  $.get "/collections.json", {}, (collections) =>
    window.model = new CollectionViewModel(collections)
    ko.applyBindings window.model
    window.model.initSammy()

    $('#collections-dummy').remove()
    $('#collections-main').show()
    $('#refine-container').show()

  # Adjust width to window
  window.adjustContainerSize = ->
    width = $(window).width()
    containerWidth = width - 80
    containerWidth = 960 if containerWidth < 960

    $('#container').width(containerWidth)
    $('#header').width(containerWidth)
    $('.BreadCrumb').width(containerWidth - 410)
    $('#right-panel').width(containerWidth - 404)
    $('.tableheader.expanded').width(containerWidth)
    $('#map').width(containerWidth - 420)
    false

  $(window).resize adjustContainerSize
  setTimeout(adjustContainerSize, 100)
