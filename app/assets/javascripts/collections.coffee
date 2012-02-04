@initCollections = (initialCollections) ->
  SITES_PER_PAGE = 25

  window.reloadMapSites = (callback) ->
    bounds = window.map.getBounds()
    ne = bounds.getNorthEast()
    sw = bounds.getSouthWest()
    $.get "/sites.json", {n: ne.lat(), e: ne.lng(), s: sw.lat(), w: sw.lng()}, (data) ->
      dataSiteIds = {}

      # Add markers if they are not already on the map
      for idx, site of data
        dataSiteIds[site.id] = site.id
        unless window.markers[site.id]
          window.markers[site.id] = new google.maps.Marker
            map: window.map
            position: new google.maps.LatLng(site.lat, site.lng)
          window.markers[site.id].siteId = site.id

      # Determine which markers need to be removed from the map
      toRemove = []
      for siteId, marker of window.markers
        unless dataSiteIds[siteId]
          toRemove.push siteId

      # And remove them
      for idx, siteId of toRemove
        window.deleteMarker siteId

      callback() if callback && typeof(callback) == 'function'

  window.setupMarkerListener = (site, marker) ->
    window.markerListener = google.maps.event.addListener marker, 'position_changed', =>
      site.position(marker.getPosition())

  window.deleteMarker = (siteId) ->
    if siteId
      window.markers[siteId].setMap null
      delete window.markers[siteId]
    else if window.marker
      window.marker.setMap null
      delete window.marker

  window.deleteMarkerListener = ->
    if window.markerListener
      google.maps.event.removeListener window.markerListener
      delete window.markerListener

  class Field
    constructor: (data) ->
      @code = ko.observable data?.code
      @name = ko.observable data?.name
      @kind = ko.observable data?.kind
      @value = ko.observable()

  class SitesContainer
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @sites = ko.observableArray()
      @expanded = ko.observable false
      @sitesPage = 1
      @hasMoreSites = ko.observable true
      @loadingSites = ko.observable false
      @siteIds = {}

    loadMoreSites: (callback) =>
      if @hasMoreSites()
        @loadingSites true
        # Fetch more sites. We fetch one more to know if we have more pages, but we discard that
        # extra element so the user always sees SITES_PER_PAGE elements.
        $.get @sitesUrl(), {offset: (@sitesPage - 1) * SITES_PER_PAGE, limit: SITES_PER_PAGE + 1}, (data) =>
          @sitesPage += 1
          if data.length == SITES_PER_PAGE + 1
            data.pop()
          else
            @hasMoreSites false
          for idx, x of data
            @addSite new Site(this, x)
          @loadingSites false
          callback() if callback && typeof(callback) == 'function'
      else
        callback() if callback && typeof(callback) == 'function'

    findSiteById: (id) =>
      for i, site of @sites()
        return site if site.id() == id

        subsite = site.findSiteById(id)
        return subsite if subsite

      null

    addSite: (site) =>
      unless @siteIds[site.id()]
        @sites.push(site)
        @siteIds[site.id()] = site

    toggle: =>
      # Load more sites when we expand, but only the first time
      if @folder() && !@expanded() && @hasMoreSites() && @sitesPage == 1
        @loadMoreSites()
      @expanded(!@expanded())

  class Collection extends SitesContainer
    constructor: (data) ->
      super
      @class = 'Collection'
      @fields = ko.observableArray()
      @fieldsInitialized = false

    sitesUrl: -> "/collections/#{@id()}/sites"

    level: -> 0

    fetchFields: =>
      unless @fieldsInitialized
        $.get "/collections/#{@id()}/fields", {}, (data) =>
          @fields $.map(data, (x) => new Field(x))

    findFieldByCode: (code) =>
      (field for field in @fields() when field.code() == code)[0]

  class Site extends SitesContainer
    constructor: (parent, data) ->
      super
      @class = 'Site'
      @parent = parent
      @selected = ko.observable()
      @id = ko.observable data?.id
      @parent_id = ko.observable data?.parent_id
      @folder = ko.observable data?.folder
      @name = ko.observable data?.name
      @lat = ko.observable data?.lat
      @lng = ko.observable data?.lng
      @position = ko.computed
        read: =>
          if @lat() && @lng()
            new google.maps.LatLng(@lat(), @lng())
          else
            null

        write: (latLng) =>
          @lat(latLng.lat())
          @lng(latLng.lng())

        owner: @
      @properties = ko.observable data?.properties
      @hasFocus = ko.observable false

    sitesUrl: -> "/sites/#{@id()}/root_sites"

    level: =>
      @parent.level() + 1

    copyPropertiesFromCollection: (collection) =>
      @properties({})
      @properties()[field.code()] = field.value() for field in collection.fields()

    copyPropertiesToCollection: (collection) =>
      if @properties()
        for key, value of @properties()
          collection.findFieldByCode(key).value(value)

    toJSON: =>
      json =
        id: @id()
        folder: @folder()
        name: @name()
      json.lat = @lat() if @lat()
      json.lng = @lng() if @lng()
      json.parent_id = @parent_id() if @parent_id()
      json.properties = @properties() if @properties()
      json

  class CollectionViewModel
    constructor: ->
      self = this

      @collections = ko.observableArray $.map(initialCollections, (x) -> new Collection(x))
      @currentCollection = ko.observable()
      @currentParent = ko.observable()
      @currentSite = ko.observable()
      @selectedSite = ko.observable()

      @currentCollection.subscribe (newValue) ->
        newValue.loadMoreSites() if newValue && newValue.sitesPage == 1

      Sammy( ->
        @get '#:collection', ->
          self.currentCollection self.findCollectionById(parseInt this.params.collection)
          self.currentCollection().fetchFields()

        @get '', ->
          self.currentCollection(null)
      ).run()

    findCollectionById: (id) =>
      (x for x in @collections() when x.id() == id)[0]

    goToRoot: ->
      location.hash = ''

    enterCollection: (collection) ->
      location.hash = "#{collection.id()}"

    editCollection: (collection) ->
      window.location = "/collections/#{collection.id()}"

    createCollection: ->
      window.location = "/collections/new"

    createGroup: =>
      parent = if @selectedSite() then @selectedSite() else @currentCollection()
      @currentSite(new Site(parent, folder: true, parent_id: @selectedSite()?.id()))

    createSite: =>
      parent = if @selectedSite() then @selectedSite() else @currentCollection()
      pos = window.map.getCenter()
      site = new Site(parent, parent_id: @selectedSite()?.id(), lat: pos.lat(), lng: pos.lng())
      site.hasFocus true
      @currentSite site

      # Add a marker to the map for setting the site's position
      window.marker = new google.maps.Marker
        position: site.position()
        animation: google.maps.Animation.DROP
        draggable: true
        map: window.map
      window.setupMarkerListener site, window.marker

    exitSite: =>
      window.deleteMarker()
      window.deleteMarkerListener()
      @currentSite(null)

    editSite: (site) =>
      site.copyPropertiesToCollection(@currentCollection())
      site.hasFocus true
      @currentSite(site)
      @selectedSite(site)

      # Pan the map to it's location, reload the sites there and make the marker editable
      unless site.folder()
        window.map.panTo(site.position())
        window.reloadMapSites =>
          window.markers[site.id()].setDraggable true
          window.setupMarkerListener site, window.markers[site.id()]

    saveSite: =>
      callback = (data) =>
        if @currentSite().id()
          # Once the site is saved after edition, we make the marker not draggable and remove the listener
          unless @currentSite().folder()
            window.markers[@currentSite().id()].setDraggable false
            window.deleteMarkerListener()
        else
          @currentSite().id(data.id)
          if @selectedSite()
            @selectedSite().addSite(@currentSite())
          else
            @currentCollection().addSite(@currentSite())

          # Once the site is saved after creation, we make the marker not draggable,
          # we remove the listener  and move it to the current markers
          unless @currentSite().folder()
            window.marker.siteId = @currentSite().id()
            window.marker.setDraggable false
            window.markers[@currentSite().id()] = window.marker
            delete window.marker

            window.deleteMarkerListener()
        @currentSite(null)

      unless @currentSite().folder()
        @currentSite().copyPropertiesFromCollection(@currentCollection())

      json = {site: @currentSite().toJSON()}

      if @currentSite().id()
        json._method = 'put'
        $.post "/collections/#{@currentCollection().id()}/sites/#{@currentSite().id()}.json", json, callback
      else
        $.post "/collections/#{@currentCollection().id()}/sites", json, callback

    selectSite: (site) =>
      if @selectedSite() == site
        @selectedSite().selected(false)
        @selectedSite(null)
      else
        @selectedSite().selected(false) if @selectedSite()
        @selectedSite(site)
        @selectedSite().selected(true)
        if @selectedSite().id() && @selectedSite().position()
          window.map.panTo(@selectedSite().position())
          window.reloadMapSites()
      site.toggle()

  window.markers = {}

  myOptions =
    center: new google.maps.LatLng(-34.397, 150.644)
    zoom: 8
    mapTypeId: google.maps.MapTypeId.ROADMAP
  window.map = new google.maps.Map document.getElementById("map"), myOptions

  window.model = new CollectionViewModel

  listener = google.maps.event.addListener window.map, 'bounds_changed', ->
    google.maps.event.removeListener listener
    window.reloadMapSites -> ko.applyBindings window.model

  google.maps.event.addListener window.map, 'dragend', -> window.reloadMapSites()
  google.maps.event.addListener window.map, 'zoom_changed', ->
    listener2 = google.maps.event.addListener window.map, 'bounds_changed', ->
      google.maps.event.removeListener listener2
      window.reloadMapSites()
