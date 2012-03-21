@initCollections = ->
  SITES_PER_PAGE = 25

  # Repesents a cluster on the map.
  # It consists of a location and a count.
  Cluster = (map, cluster) ->
    @map = map
    @setMap map
    @maxZoom = cluster.max_zoom
    @setData(cluster, false)

  Cluster.prototype = new google.maps.OverlayView

  Cluster.prototype.onAdd = ->
    @div = document.createElement 'DIV'
    @div.className = 'cluster'
    @shadow = document.createElement 'DIV'
    @shadow.className = 'cluster-shadow'
    @countDiv = document.createElement 'DIV'
    @countDiv.className = 'cluster-count'
    @setCount @count

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
        @map.panTo @position
        nextZoom = (if @maxZoom then @maxZoom else @map.getZoom()) + 1
        @map.setZoom nextZoom

    @divDownListener = google.maps.event.addDomListener @divClick, 'mousedown', listenerDownCallback
    @divUpListener = google.maps.event.addDomListener @divClick, 'mouseup', listenerUpCallback

    @countDownListener = google.maps.event.addDomListener @countClick, 'mousedown', listenerDownCallback
    @countUpListener = google.maps.event.addDomListener @countClick, 'mouseup', listenerUpCallback

  Cluster.prototype.draw = ->
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

  Cluster.prototype.onRemove = ->
    google.maps.event.removeListener @divDownListener
    google.maps.event.removeListener @divUpListener
    google.maps.event.removeListener @countDownListener
    google.maps.event.removeListener @countUpListener
    @div.parentNode.removeChild @div
    @shadow.parentNode.removeChild @shadow
    @countDiv.parentNode.removeChild @countDiv
    @divClick.parentNode.removeChild @divClick
    @countClick.parentNode.removeChild @countClick

  Cluster.prototype.setData = (cluster, draw = true) ->
    @position = new google.maps.LatLng(cluster.lat, cluster.lng)
    @setCount cluster.count
    @draw() if draw

  Cluster.prototype.setCount = (count) ->
    @count = count
    @countDiv.innerText = (@count).toString() if @countDiv

  Cluster.prototype.setActive = (draw = true) ->
    $(@div).removeClass('inactive')
    $(@shadow).removeClass('inactive')
    @draw() if draw

  Cluster.prototype.setInactive = (draw = true) ->
    $(@div).addClass('inactive')
    @draw() if draw

  Cluster.prototype.adjustZIndex = ->
    zIndex = window.model.zIndex(@position.lat())
    @div.style.zIndex = zIndex if @div
    @countDiv.style.zIndex = zIndex - 10 if @countDiv

  # A Layer field
  class Field
    constructor: (data) ->
      @code = ko.observable data?.code
      @name = ko.observable data?.name
      @kind = ko.observable data?.kind
      @options = if data.config?.options?
                   ko.observableArray($.map(data.config.options, (x) => new Option(x)))
                 else
                   ko.observableArray()
      @optionsCodes = ko.computed => $.map(@options(), (x) => x.code())
      @value = ko.observable()
      @hasValue = ko.computed => @value() && (if @kind() == 'select_many' then @value().length > 0 else @value())
      @valueUI = ko.computed => @valueUIFor(@value())
      @remainingOptions = ko.computed =>
        if @value()
          @options().filter((x) => @value().indexOf(x.code()) == -1)
        else
          @options()

      @editing = ko.observable false

    # The value of the UI.
    # If it's a select one or many, we need to get the label from the option code.
    valueUIFor: (value) =>
      if @kind() == 'select_one'
        if value then @labelFor(value) else ''
      else if @kind() == 'select_many'
        if value then $.map(value, (x) => @labelFor(x)).join(', ') else ''
      else
        value

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

    selectOption: (option) =>
      @value([]) unless @value()
      @value().push(option.code())
      @value.valueHasMutated()

    removeOption: (optionCode) =>
      @value([]) unless @value()
      @value(@value().diff([optionCode]))
      @value.valueHasMutated()

    labelFor: (code) =>
      for option in @options()
        if option.code() == code
          return option.label()
      null

    # In the table view, use a fixed size width for each property column,
    # which depends on the length of the name.
    suggestedWidth: =>
      if @name().length < 10
        '100px'
      else
        "#{@name().length * 8}px"

  class Option
    constructor: (data) ->
      @code = ko.observable(data?.code)
      @label = ko.observable(data?.label)

  # An object with a position on the map.
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

    # Pans the map to this object's location, and the reload the map's sites and clusters.
    panToPosition: =>
      currentPosition = window.model.map.getCenter()
      positionChanged = @position() && (Math.abs(@position().lat() - currentPosition.lat()) > 1e-6 || Math.abs(@position().lng() - currentPosition.lng()) > 1e-6)

      window.model.reloadMapSitesAutomatically = false
      window.model.map.panTo @position() if positionChanged

      # We also zoom the map to the minZoom given of this site/group.
      if @minZoom?
        # But in the case of a site (no max zoom), we don't want to zoom
        # out if the user already zoomed beyong the minZoom (annoying)
        unless !@maxZoom && @minZoom < window.model.map.getZoom()
          zoom = if @minZoom == 0 then @maxZoom else @minZoom
          window.model.map.setZoom zoom
      else if !@maxZoom?
        # This is the case of a collection, which doesn't have minZoom nor maxZoom
        window.model.map.setZoom @defaultZoom() if @defaultZoom()?
      window.model.reloadMapSites()

  # An object that contains sites. This is a base class for Site and Collection.
  # Initially, the contained sites are empty. To load more, invoke 'loadMoreSites'.
  class SitesContainer extends Locatable
    constructor: (data) ->
      super(data)
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @updatedAt = ko.observable(data.updated_at)
      @updatedAtTimeago = ko.computed => if @updatedAt() then $.timeago(@updatedAt()) else ''
      @sites = ko.observableArray()
      @expanded = ko.observable false
      @sitesPage = 1
      @hasMoreSites = ko.observable true
      @loadingSites = ko.observable false

    # Loads SITES_PER_PAGE sites more from the server, it there are more sites.
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
        window.model.refreshTimeago()

    addSite: (site) =>
      unless window.model.siteIds[site.id()]
        # This check is because the selected site might be selected on the map,
        # but not in the tree. So we use that one instead of the one from the server,
        # and set it's parent to this site.
        if window.model.selectedSite()?.id() == site.id()
          window.model.selectedSite().parent = @
          @sites.push(window.model.selectedSite())
        else
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

    defaultZoom: -> 4

    fetchLocation: => $.get "/collections/#{@id()}.json", {}, (data) =>
      @position(data)
      @updatedAt(data.updated_at)

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

    propagateUpdatedAt: (value) =>
      @updatedAt(value)

  class Site extends SitesContainer
    constructor: (parent, data) ->
      super(data)
      @parent = parent
      @selected = ko.observable()
      @id = ko.observable data?.id
      @parentId = ko.observable data?.parent_id
      @group = ko.observable data?.group
      @name = ko.observable data?.name
      @minZoom = data?.min_zoom
      @maxZoom = data?.max_zoom
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

    defaultZoom: -> @parent.minZoom

    parentCollection: => @parent.parentCollection()

    hasLocation: => @position() && !(@group() && @locationMode() == 'none')

    hasName: => $.trim(@name()).length > 0

    propertyValue: (field) =>
      value = @properties()[field.code()]
      field.valueUIFor(value)

    fetchLocation: =>
      $.get "/sites/#{@id()}.json", {}, (data) =>
        @position(data)
        @updatedAt(data.updated_at)
      @parent.fetchLocation()

    updateProperty: (code, value) =>
      @properties()[code] = value
      $.post "/sites/#{@id()}/update_property.json", {code: code, value: value}, (data) =>
        @propagateUpdatedAt(data.updated_at)

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
          for field in collection.fields()
            value = @properties()[field.code()]
            field.value(value)

    post: (json, callback) =>
      callback_with_updated_at = (data) =>
        @propagateUpdatedAt(data.updated_at)
        callback(data) if callback && typeof(callback) == 'function'

      data = {site: json}
      if @id()
        data._method = 'put'
        $.post "/collections/#{@parentCollection().id()}/sites/#{@id()}.json", data, callback_with_updated_at
      else
        $.post "/collections/#{@parentCollection().id()}/sites", data, callback_with_updated_at

    propagateUpdatedAt: (value) =>
      @updatedAt(value)
      @parent.propagateUpdatedAt(value)

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
        if @marker
          @setupMarkerListener()
        else
          @createMarker()
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

    tryGeolocateName: =>
      return if @nameBeforeGeolocateName == @name()

      @nameBeforeGeolocateName = @name()
      @parseLocation text: @fullName(), success: (position) =>
        @position(position)
        @marker.setPosition(position)
        @panToPosition()

    fullName: =>
      name = @name()

      nextParent = @parent
      while nextParent
        name += ", "
        name += nextParent.name()
        nextParent = nextParent.parent

      name

    parseLocation: (options) =>
      text = options.text || @locationTextTemp
      if match = text.match(/^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$/)
        options.success(new google.maps.LatLng(parseFloat(match[1]), parseFloat(match[2])))
      else
        window.model.geocoder.geocode { 'address': text}, (results, status) =>
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
        zIndex: 200000
      @setupMarkerListener()
      window.model.setAllMarkersInactive() if draggable

    deleteMarker: (removeFromMap = true) =>
      return unless @marker
      @marker.setMap null if removeFromMap
      delete @marker
      @deleteMarkerListener() if removeFromMap

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
      @newSite = ko.computed => if @editingSite() && !@editingSite().id() && !@editingSite().group() then @editingSite() else null
      @newGroup = ko.computed => if @editingSite() && !@editingSite().id() && @editingSite().group() then @editingSite() else null
      @showSite = ko.computed => if @editingSite()?.id() && !@editingSite().group() then @editingSite() else null
      @showGroup = ko.computed => if @editingSite()?.id() && @editingSite().group() then @editingSite() else null
      @showingMap = ko.observable(true)
      @sitesCount = ko.observable(0)
      @markers = {}
      @clusters = {}
      @siteIds = {}
      @reloadMapSitesAutomatically = true
      @requestNumber = 0
      @geocoder = new google.maps.Geocoder();

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
          @editingSite().updatedAt(data.updated_at)
          @editingSite().parent.addSite(@editingSite())

        @editingSite().position(data)
        @editingSite().parent.fetchLocation()
        @editingSite().deleteMarker()

        @selectedSite(@editingSite().parent) if @editingSite().parentId()

        @exitSite()

      unless @editingSite().group()
        @editingSite().copyPropertiesFromCollection(@currentCollection())

      @editingSite().post @editingSite().toJSON(), callback

    exitSite: =>
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
          # This is to prevent flicker: when the map reloads, we try to reuse the old site marker
          if @selectedSite().marker
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
        exclude_id: if @selectedSite()?.id() && !@selectedSite().group() then @selectedSite().id() else null

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
      editingSiteId = if @editingSite()?.id() && @editingSite().editingLocation() then @editingSite().id() else null
      selectedSiteId = @selectedSite()?.id()
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
            if selectedSiteId && selectedSiteId == site.id
              markerOptions.icon = @markerImageTarget
              markerOptions.shadow = @markerImageTargetShadow
            @markers[site.id] = new google.maps.Marker markerOptions
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
        @oldSelectedSite.deleteMarker()
        delete @oldSelectedSite

    drawClustersInMap: (clusters = []) =>
      dataClusterIds = {}

      # Add clusters if they are not already on the map
      for cluster in clusters
        dataClusterIds[cluster.id] = cluster.id
        currentCluster = @clusters[cluster.id]
        if currentCluster
          currentCluster.setData(cluster)
        else
          @createCluster(cluster)

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
        unless $('table.GralTable').hasClass("fht-table")
          $('table.GralTable').fixedHeaderTable footer: false, cloneHeadToFoot: false, themeClass: 'GralTable'

  $.get "/collections.json", {}, (collections) =>
    window.model = new CollectionViewModel(collections)
    ko.applyBindings window.model
    window.model.initSammy()

    $('#collections-dummy').remove()
    $('#collections-main').show()

  # Adjust width to window
  window.adjustContainerSize = ->
    width = $(window).width()
    containerWidth = width - 80
    containerWidth = 960 if containerWidth < 960

    # Using $(...).width(...) breaks the layout, don't know why
    $('#container').get(0).style.width = "#{containerWidth}px"
    $('#header').get(0).style.width = "#{containerWidth}px"
    $('.BreadCrumb').get(0).style.width = "#{containerWidth - 340}px"
    $('#container .right').get(0).style.width = "#{containerWidth - 334}px"
    $('.tableheader.expanded').get(0).style.width = "#{containerWidth}px" if ($('.tableheader.expanded').length > 0)
    $('#map').get(0).style.width = "#{containerWidth - 350}px" if $('#map').length > 0
    false

  $(window).resize adjustContainerSize
  setTimeout(adjustContainerSize, 100)
