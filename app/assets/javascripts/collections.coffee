@initCollections = (initialCollections) ->
  reloadMapSites = (callback) ->
    bounds = window.map.getBounds()
    ne = bounds.getNorthEast()
    sw = bounds.getSouthWest()
    $.get "/sites.json", {n: ne.lat(), e: ne.lng(), s: sw.lat(), w: sw.lng()}, (data) ->
      dataSiteIds = {}

      for idx, site of data
        dataSiteIds[site.id] = site.id
        unless window.markers[site.id]
          window.markers[site.id] = new google.maps.Marker
            map: window.map
            position: new google.maps.LatLng(site.lat, site.lng)

      toRemove = []

      for siteId, marker of window.markers
        unless dataSiteIds[siteId]
          toRemove.push siteId

      for idx, siteId of toRemove
        window.markers[siteId].setMap(null)
        delete window.markers[siteId]

      callback() if callback

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
      @sitesInitialized = false

    fetchSites: (callback) =>
      if @sitesInitialized
        callback() if callback
      else
        @sitesInitialized = true
        $.get @sitesUrl(), {}, (data) =>
          @sites $.map(data, (x) => new Site(this, x))
          callback() if callback

    findSiteById: (id) =>
      for i, site of @sites()
        return site if site.id() == id

        subsite = site.findSiteById(id)
        return subsite if subsite

      null

    addSite: (site) =>
      @fetchSites =>
        @sites().push(site)

    toggle: =>
      @fetchSites() unless @expanded()
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
        newValue.fetchSites() if newValue

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
      @currentSite(new Site(parent, parent_id: @selectedSite()?.id(), lat: pos.lat(), lng: pos.lng()))

    exitSite: =>
      @currentSite(null)

    editSite: (site) =>
      site.copyPropertiesToCollection(@currentCollection())
      @currentSite(site)

    saveSite: =>
      callback = (data) =>
        if !@currentSite().id()
          @currentSite().id(data.id)
          if @selectedSite()
            if @selectedSite().sitesInitialized
              @selectedSite().sites.push(@currentSite())
          else
            @currentCollection().addSite(@currentSite())
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
    reloadMapSites -> ko.applyBindings window.model

  google.maps.event.addListener window.map, 'dragend', -> reloadMapSites()
  google.maps.event.addListener window.map, 'zoom_changed', ->
    listener2 = google.maps.event.addListener window.map, 'bounds_changed', ->
      google.maps.event.removeListener listener2
      reloadMapSites()
