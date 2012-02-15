@initCollections = ->
  SITES_PER_PAGE = 25

  Cluster = (map, cluster) ->
    @position = new google.maps.LatLng(cluster.lat, cluster.lng)
    @count = cluster.count
    @map = map
    @setMap map
    @maxZoom = cluster.max_zoom

  Cluster.prototype = new google.maps.OverlayView

  Cluster.prototype.onAdd = ->
    @div = document.createElement 'DIV'
    @div.className = 'cluster'
    @div.innerText = (@count).toString()

    [@image, @width, @height] = if @count < 10 then [1, 53, 52] else
                                if @count < 25 then [2, 56, 55] else
                                if @count < 50 then [3, 66, 65] else
                                if @count < 100 then [4, 78, 77]
                                else [5, 90, 89]

    @div.style.backgroundImage = "url('http://google-maps-utility-library-v3.googlecode.com/svn/trunk/markerclusterer/images/m#{@image}.png')"
    @div.style.width = "#{@width}px"
    @div.style.height = @div.style.lineHeight = "#{@height}px"

    @getPanes().overlayMouseTarget.appendChild @div

    @listener = google.maps.event.addDomListener @div, 'click', =>
      @map.panTo @position
      nextZoom = (if @maxZoom then @maxZoom else @map.getZoom()) + 1
      @map.setZoom nextZoom

  Cluster.prototype.draw = ->
    pos = @getProjection().fromLatLngToDivPixel @position
    @div.style.left = "#{pos.x - @width / 2}px"
    @div.style.top = "#{pos.y - @height / 2}px"

  Cluster.prototype.onRemove = ->
    google.maps.event.removeListener @listener
    @div.parentNode.removeChild @div
    delete @div

  class Field
    constructor: (data) ->
      @code = ko.observable data?.code
      @name = ko.observable data?.name
      @kind = ko.observable data?.kind
      @value = ko.observable()
      @valueText = ko.computed => if @value() then @value() else '(no value)'
      @editing = ko.observable false

    edit: =>
      @originalValue = @value()
      @editing(true)

    keyPress: (field, event) =>
      switch event.keyCode
        when 13 then @save()
        when 27 then @exit()
        else true

    exit: =>
      @value(@originalValue) if @originalValue?
      @editing(false)
      delete @originalValue

    save: =>
      @editing(false)
      window.model.editingSite().updateProperty(@code(), @value())
      delete @originalValue

  class Locatable
    constructor: (data) ->
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

    panToPosition: (callback) =>
      window.model.reloadMapSitesAutomatically = false
      window.model.map.panTo @position() if @position()
      window.model.reloadMapSites callback: callback, reuseCurrentClusters: false

  class SitesContainer extends Locatable
    constructor: (data) ->
      super(data)
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @sites = ko.observableArray()
      @expanded = ko.observable false
      @sitesPage = 1
      @hasMoreSites = ko.observable true
      @loadingSites = ko.observable false

    loadMoreSites: =>
      return unless @hasMoreSites()

      @loadingSites true
      # Fetch more sites. We fetch one more to know if we have more pages, but we discard that
      # extra element so the user always sees SITES_PER_PAGE elements.
      $.get @sitesUrl(), {offset: (@sitesPage - 1) * SITES_PER_PAGE, limit: SITES_PER_PAGE + 1}, (data) =>
        @sitesPage += 1
        if data.length == SITES_PER_PAGE + 1
          data.pop()
        else
          @hasMoreSites false
        for site in data
          @addSite new Site(this, site)
        @loadingSites false

    addSite: (site) =>
      unless window.model.siteIds[site.id()]
        @sites.push(site)
        window.model.siteIds[site.id()] = site

    removeSite: (site) =>
      @sites.remove site
      delete window.model.siteIds[site.id()]

    toggle: =>
      # Load more sites when we expand, but only the first time
      if @group() && !@expanded() && @hasMoreSites() && @sitesPage == 1
        @loadMoreSites()
      @expanded(!@expanded())

  class Collection extends SitesContainer
    constructor: (data) ->
      super(data)
      @fields = ko.observableArray()
      @checked = ko.observable true
      @fieldsInitialized = false

    sitesUrl: -> "/collections/#{@id()}/sites"

    level: -> 0

    fetchLocation: => $.get "/collections/#{@id()}.json", {}, @position

    fetchFields: (callback) =>
      if @fieldsInitialized
        callback() if callback && typeof(callback) == 'function'
        return

      @fieldsInitialized = true
      $.get "/collections/#{@id()}/fields", {}, (data) =>
        @fields($.map(data, (x) => new Field(x)))
        callback() if callback && typeof(callback) == 'function'

    findFieldByCode: (code) => (field for field in @fields() when field.code() == code)[0]

    clearFieldValues: =>
      field.value(null) for field in @fields()

    parentCollection: => @

  class Site extends SitesContainer
    constructor: (parent, data) ->
      super(data)
      @parent = parent
      @selected = ko.observable()
      @id = ko.observable data?.id
      @parentId = ko.observable data?.parent_id
      @group = ko.observable data?.group
      @name = ko.observable data?.name
      @locationMode = ko.observable data?.location_mode
      @properties = ko.observable data?.properties
      @editingName = ko.observable(false)
      @editingLocation = ko.observable(false)
      @editingLocationMode = ko.observable(false)
      @locationText = ko.computed
        read: => (Math.round(@lat() * 100000) / 100000) + ', ' + (Math.round(@lng() * 100000) / 100000)
        write: (value) => @locationTextTemp = value
        owner: @
      @locationTextTemp = @locationText()
      @valid = ko.computed => @hasName()

    sitesUrl: -> "/sites/#{@id()}/root_sites"

    level: => @parent.level() + 1

    parentCollection: => @parent.parentCollection()

    hasLocation: => @position() && !(@group() && @locationMode() == 'none')

    hasName: => $.trim(@name()).length > 0

    fetchLocation: =>
      $.get "/sites/#{@id()}.json", {}, @position
      @parent.fetchLocation()

    updateProperty: (code, value) =>
      @properties()[code] = value
      $.post "/sites/#{@id()}/update_property", {code: code, value: value}

    copyPropertiesFromCollection: (collection) =>
      @properties({})
      for field in collection.fields()
        if field.value()
          @properties()[field.code()] = field.value()
        else
          delete @properties()[field.code()]

    copyPropertiesToCollection: (collection) =>
      collection.fetchFields =>
        collection.clearFieldValues()
        if @properties()
          for key, value of @properties()
            collection.findFieldByCode(key).value(value)

    post: (json, callback) =>
      data = {site: json}
      if @id()
        data._method = 'put'
        $.post "/collections/#{@parentCollection().id()}/sites/#{@id()}.json", data, callback
      else
        $.post "/collections/#{@parentCollection().id()}/sites", data, callback

    editName: =>
      @originalName = @name()
      @editingName(true)

    nameKeyPress: (site, event) =>
      switch event.keyCode
        when 13 then @saveName()
        when 27 then @exitName()
        else true

    saveName: =>
      if @hasName()
        @post name: @name()
        @editingName(false)
      else
        @exitName()

    exitName: =>
      @name(@originalName)
      @editingName(false)
      delete @originalName

    editLocation: =>
      @editingLocation(true)
      @startEditLocationInMap()

    startEditLocationInMap: =>
      @originalLocation = @position()
      if @group()
        if @locationMode() == 'manual'
          @createMarker()
        else
          @subscribeToLocationModeChange()
      else
        @createMarker() unless @marker
        @marker.setDraggable(true)
      window.model.setAllMarkersInactive()
      @panToPosition()

    endEditLocationInMap: (position) =>
      @editingLocation(false)
      @position(position)
      if @group()
        @deleteMarker()
        @unsubscribeToLocationModeChange()
      else
        @marker.setPosition(@position())
        @marker.setDraggable false
      window.model.setAllMarkersActive()
      @panToPosition()

    locationKeyPress: (site, event) =>
      switch event.keyCode
        when 13 then @saveLocation()
        when 27 then @exitLocation()
        else true

    saveLocation: =>
      window.model.setAllMarkersActive()

      save = =>
        @post lat: @lat(), lng: @lng(), (data) =>
          @parent.fetchLocation()
          @endEditLocationInMap(data)

      @parseLocation
        success: (position) => @position(position); save()
        failure: (position) => @position(position); @endEditLocationInMap(position)

    newLocationKeyPress: (site, event) =>
      switch event.keyCode
        when 13
          @moveLocation()
          false
        else true

    moveLocation: =>
      callback = (position) =>
        @position(position)
        @marker.setPosition(position)
        @panToPosition()

      @parseLocation success: callback, failure: callback

    parseLocation: (options) =>
      if match = @locationTextTemp.match(/^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$/)
        options.success(new google.maps.LatLng(parseFloat(match[1]), parseFloat(match[2])))
      else
        window.model.geocoder.geocode { 'address': @locationTextTemp}, (results, status) =>
          if results.length > 0
            options.success(results[0].geometry.location)
          else
            options.failure(@originalLocation)

    exitLocation: =>
      @endEditLocationInMap(@originalLocation)
      delete @originalLocation

    editLocationMode: =>
      @editingLocationMode(true)

    exitLocationMode: =>
      @editingLocationMode(false)

    saveLocationMode: =>
      @editingLocationMode(false)
      @editLocation() if @locationMode() == 'manual'

      @post location_mode: @locationMode(), lat: @lat(), lng: @lng(), (data) =>
        @position(data)
        @parent.fetchLocation()
        @panToPosition()

    createMarker: (drop = false) =>
      @deleteMarker()

      draggable = @group() || @editingLocation() || !@id()
      @marker = new google.maps.Marker
        map: window.model.map
        position: @position()
        animation: if drop || !@id() then google.maps.Animation.DROP else null
        draggable: draggable
        icon: window.model.markerImageTarget
        shadow: window.model.markerImageTargetShadow
      @setupMarkerListener()
      window.model.setAllMarkersInactive() if draggable

    deleteMarker: =>
      return unless @marker
      @marker.setMap null
      delete @marker
      @deleteMarkerListener()

    deleteMarkerListener: =>
      return unless @markerListener
      google.maps.event.removeListener @markerListener
      delete @markerListener

    setupMarkerListener: =>
      @markerListener = google.maps.event.addListener @marker, 'position_changed', =>
        @position(@marker.getPosition())
        @locationText("#{@marker.getPosition().lat()}, #{@marker.getPosition().lng()}")

    subscribeToLocationModeChange: =>
      @subscription = @locationMode.subscribe (newLocationMode) =>
        if newLocationMode == 'manual'
          @createMarker true
        else
          @deleteMarker()

    unsubscribeToLocationModeChange: =>
      return unless @subscription
      @subscription.dispose()
      delete @subscription

    toJSON: =>
      json =
        id: @id()
        group: @group()
        name: @name()
      json.lat = @lat() if @lat()
      json.lng = @lng() if @lng()
      json.parent_id = @parentId() if @parentId()
      json.properties = @properties() if @properties()
      json.location_mode = @locationMode() if @locationMode()
      json

  class CollectionViewModel
    constructor: (collections, lat, lng) ->
      self = this

      @collections = ko.observableArray $.map(collections, (x) -> new Collection(x))
      @currentCollection = ko.observable()
      @currentParent = ko.observable()
      @editingSite = ko.observable()
      @selectedSite = ko.observable()
      @newSite = ko.computed => if @editingSite() && !@editingSite().id() && !@editingSite().group() then @editingSite() else null
      @newGroup = ko.computed => if @editingSite() && !@editingSite().id() && @editingSite().group() then @editingSite() else null
      @showSite = ko.computed => if @editingSite()?.id() && !@editingSite().group() then @editingSite() else null
      @showGroup = ko.computed => if @editingSite()?.id() && @editingSite().group() then @editingSite() else null
      @collectionsCenter = new google.maps.LatLng(lat, lng)
      @markers = {}
      @clusters = {}
      @siteIds = {}
      @reloadMapSitesAutomatically = true
      @requestNumber = 0
      @geocoder = new google.maps.Geocoder();

      @markerImageInactive = new google.maps.MarkerImage(
        "/assets/marker_sprite_inactive.png", new google.maps.Size(20, 34), new google.maps.Point(0, 0), new google.maps.Point(10, 34)
      )
      @markerImageInactiveShadow = new google.maps.MarkerImage(
        "/assets/marker_sprite_inactive.png", new google.maps.Size(37, 34), new google.maps.Point(20, 0), new google.maps.Point(10, 34)
      )
      @markerImageTarget = new google.maps.MarkerImage(
        "/assets/marker_sprite_target.png", new google.maps.Size(20, 34), new google.maps.Point(0, 0), new google.maps.Point(10, 34)
      )
      @markerImageTargetShadow = new google.maps.MarkerImage(
        "/assets/marker_sprite_target.png", new google.maps.Size(37, 34), new google.maps.Point(20, 0), new google.maps.Point(10, 34)
      )

      Sammy( ->
        @get '#:collection', ->
          collection = self.findCollectionById parseInt(this.params.collection)
          initialized = self.initMap collection

          self.currentCollection collection
          self.selectSite(self.selectedSite()) if self.selectedSite()

          collection.loadMoreSites() if collection.sitesPage == 1
          self.selectSite(self.selectedSite()) if self.selectedSite()

          collection.fetchFields()
          collection.panToPosition() unless initialized

        @get '', ->
          initialized = self.initMap()
          self.currentCollection(null)
          self.selectSite(self.selectedSite()) if self.selectedSite()

          self.reloadMapSites() unless initialized
      ).run()

      $.each @collections(), (idx) =>
        @collections()[idx].checked.subscribe (newValue) =>
          @reloadMapSites reuseCurrentClusters: false

    findCollectionById: (id) => (x for x in @collections() when x.id() == id)[0]

    goToRoot: -> location.hash = ''

    enterCollection: (collection) -> location.hash = "#{collection.id()}"

    editCollection: (collection) -> window.location = "/collections/#{collection.id()}"

    createCollection: -> window.location = "/collections/new"

    createGroup: => @createSiteOrGroup true

    createSite: => @createSiteOrGroup false

    createSiteOrGroup: (group) =>
      parent = if @selectedSite() then @selectedSite() else @currentCollection()
      pos = @originalSiteLocation = @map.getCenter()
      site = if group
               new Site(parent, parent_id: @selectedSite()?.id(), lat: pos.lat(), lng: pos.lng(), group: group, location_mode: 'auto')
             else
               new Site(parent, parent_id: @selectedSite()?.id(), lat: pos.lat(), lng: pos.lng(), group: group)
      @editingSite site
      @editingSite().copyPropertiesToCollection(@currentCollection()) unless @editingSite().group()
      @editingSite().startEditLocationInMap()

    editSite: (site) =>
      site.copyPropertiesToCollection(site.parentCollection())
      @selectSite(site) unless @selectedSite() && @selectedSite().id() == site.id()
      @editingSite(site)

    editSiteFromMarker: (siteId) =>
      site = @siteIds[siteId]
      if site
        @editSite site
      else
        $.get "/sites/#{siteId}.json", {}, (data) =>
          parent = window.model.findCollectionById(data.collection_id)
          site = new Site(parent, data)
          @editSite site

    saveSite: =>
      return unless @editingSite().valid()

      callback = (data) =>
        unless @editingSite().id()
          @editingSite().id(data.id)
          @editingSite().parent.addSite(@editingSite())

        @editingSite().position(data)
        @editingSite().parent.fetchLocation()

        @selectedSite(@editingSite())
        @selectedSite().deleteMarker()
        @exitSite()

      unless @editingSite().group()
        @editingSite().copyPropertiesFromCollection(@currentCollection())

      @editingSite().post @editingSite().toJSON(), callback

    exitSite: =>
      @editingSite().unsubscribeToLocationModeChange()
      @editingSite().editingLocation(false)
      @editingSite().deleteMarker() unless @editingSite().id()
      @editingSite(null)
      window.model.setAllMarkersActive()

    deleteSite: =>
      if confirm("Are you sure you want to delete #{@editingSite().name()}?")
        @selectSite(@editingSite())
        @editingSite().parent.removeSite(@editingSite())
        $.post "/sites/#{@editingSite().id()}", {_method: 'delete'}, =>
          @editingSite().parent.fetchLocation()
          @editingSite().deleteMarker()
          @exitSite()
          @reloadMapSites reuseCurrentClusters: false

    selectSite: (site) =>
      if @selectedSite()
        @selectedSite().selected(false)
        @selectedSite().deleteMarker()
      if @selectedSite() == site
        @selectedSite(null)
        @reloadMapSites reuseCurrentClusters: false
      else
        @selectedSite(site)
        @selectedSite().selected(true)
        if @selectedSite().id() && @selectedSite().hasLocation()
          @selectedSite().createMarker() unless @selectedSite().group()
          @selectedSite().panToPosition()

    toggleSite: (site) =>
      site.toggle()

    initMap: (collection) =>
      return false if @map

      mapOptions =
        center: if collection?.position() then collection.position() else @collectionsCenter
        zoom: 4
        mapTypeId: google.maps.MapTypeId.ROADMAP
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

    reloadMapSites: (options = {}) =>
      bounds = @map.getBounds()

      # Wait until map is loaded
      unless bounds
        setTimeout(( => @reloadMapSites(options)), 100)
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
        exclude_id: if @selectedSite()?.id() && !@selectedSite().group() then @selectedSite().id() else null

      @requestNumber += 1
      currentRequestNumber = @requestNumber

      getCallback = (data = {}) =>
        return unless currentRequestNumber == @requestNumber

        @drawSitesInMap data.sites
        @drawClustersInMap data.clusters, options.reuseCurrentClusters
        @reloadMapSitesAutomatically = true

        options.callback() if options.callback && typeof(options.callback) == 'function'

      if query.collection_ids.length == 0
        # Save a request to the server if there are no selected collections
        getCallback()
      else
        $.get "/sites/search.json", query, getCallback

    drawSitesInMap: (sites = []) =>
      dataSiteIds = {}
      editingSiteId = if @editingSite()?.id() && @editingSite().editingLocation() then @editingSite().id() else null
      selectedSiteId = @selectedSite()?.id()

      # Add markers if they are not already on the map
      for site in sites
        dataSiteIds[site.id] = site.id
        unless @markers[site.id]
          markerOptions =
            map: @map
            position: new google.maps.LatLng(site.lat, site.lng)
          # Show site in grey if editing a site (but not if it's the one being edited)
          if editingSiteId && editingSiteId != site.id
            markerOptions.icon = @markerImageInactive
            markerOptions.shadow = @markerImageInactiveShadow
          if selectedSiteId && selectedSiteId == site.id
            markerOptions.icon = @markerImageTarget
            markerOptions.shadow = @markerImageTargetShadow
          @markers[site.id] = new google.maps.Marker markerOptions
          localId = @markers[site.id].siteId = site.id
          do (localId) =>
            @markers[localId].listener = google.maps.event.addListener @markers[localId], 'click', (event) =>
              @editSiteFromMarker localId

      # Determine which markers need to be removed from the map
      toRemove = []
      for siteId, marker of @markers
        toRemove.push siteId unless dataSiteIds[siteId]

      # And remove them
      for siteId in toRemove
        @deleteMarker siteId

    drawClustersInMap: (clusters = [], reuseCurrentClusters = true) =>
      if reuseCurrentClusters
        dataClusterIds = {}

        # Add clusters if they are not already on the map
        for cluster in clusters
          dataClusterIds[cluster.id] = cluster.id
          @createCluster(cluster) unless @clusters[cluster.id]

        # Determine which clusters need to be removed from the map
        toRemove = []
        for clusterId, cluster of @clusters
          toRemove.push clusterId unless dataClusterIds[clusterId]

        # And remove them
        @deleteCluster clusterId for clusterId in toRemove
      else
        toRemove = []
        for clusterId, cluster of @clusters
          toRemove.push clusterId

        @deleteCluster clusterId for clusterId in toRemove
        @createCluster(cluster) for cluster in clusters

    setAllMarkersInactive: =>
      editingSiteId = @editingSite()?.id()?.toString()
      for siteId, marker of @markers
        @setMarkerIcon marker, (if editingSiteId == siteId then 'target' else 'inactive')

    setAllMarkersActive: =>
      selectedSiteId = @selectedSite()?.id()?.toString()
      for siteId, marker of @markers
        @setMarkerIcon marker, (if selectedSiteId == siteId then 'target' else 'active')

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

    deleteMarker: (siteId) =>
      return unless @markers[siteId]
      @markers[siteId].setMap null
      google.maps.event.removeListener @markers[siteId].listener
      delete @markers[siteId]

    createCluster: (cluster) =>
      @clusters[cluster.id] = new Cluster @map, cluster

    deleteCluster: (id) =>
      @clusters[id].setMap null
      delete @clusters[id]

  $.get "/collections.json", {}, (collections) =>
    # Compute all collections lat/lng: the center of all collections
    sum_lat = 0
    sum_lng = 0
    count = 0
    for collection in collections when collection.lat && collection.lng
      sum_lat += parseFloat(collection.lat)
      sum_lng += parseFloat(collection.lng)
      count += 1

    if count == 0
      sum_lat = 10
      sum_lng = 90
    else
      sum_lat /= count
      sum_lng /= count

    window.model = new CollectionViewModel(collections, sum_lat, sum_lng)
    ko.applyBindings window.model

    $('#collections-dummy').hide()
    $('#collections-main').show()
