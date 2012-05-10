$(-> if $('#collections-main').length > 0

  SITES_PER_PAGE = 25

  # An object with a position on the map.
  class window.Locatable
    constructor: (data) ->
      @constructorLocation(data)

    constructorLocation: (data) ->
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
      window.model.reloadMapSites()

  class window.SitesContainer extends Locatable
    constructor: (data) ->
      super(data)

      @initSites()

    initSites: =>
      @expanded = ko.observable false
      @sites = ko.observableArray()
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
          @addSite @createSite(site)
        @loadingSites false
        window.model.refreshTimeago()

    addSite: (site, isNew = false) =>
      # This check is because the selected site might be selected on the map,
      # but not in the tree. So we use that one instead of the one from the server,
      # and set its collection to ourself.
      if window.model.selectedSite()?.id() == site.id()
        site = window.model.selectedSite()
      else
        site = window.model.siteIds[site.id()] if window.model.siteIds[site.id()]

      @sites.push(site)

      window.model.siteIds[site.id()] = site

    removeSite: (site) =>
      @sites.remove site
      delete window.model.siteIds[site.id()]

    toggleExpand: =>
      # Load more sites when we expand, but only the first time
      if !@expanded() && @hasMoreSites() && @sitesPage == 1
        @loadMoreSites()
      @expanded(!@expanded())

    createSite: (site) => new Site(@, site)

  class window.CollectionBase extends SitesContainer
    constructor: (data) ->
      super(data)
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @updatedAt = ko.observable(data.updated_at)
      @updatedAtTimeago = ko.computed => if @updatedAt() then $.timeago(@updatedAt()) else ''

    fetchFields: (callback) =>
      if @fieldsInitialized
        callback() if callback && typeof(callback) == 'function'
        return

      @fieldsInitialized = true
      $.get "/collections/#{@id()}/fields", {}, (data) =>
        @layers($.map(data, (x) => new Layer(x)))

        fields = []
        for layer in @layers()
          for field in layer.fields()
            fields.push(field)

        @fields(fields)
        callback() if callback && typeof(callback) == 'function'

    findFieldByCode: (code) => (field for field in @fields() when field.code() == code)[0]

    clearFieldValues: =>
      field.value(null) for field in @fields()

    propagateUpdatedAt: (value) =>
      @updatedAt(value)

    link: (format) => "/api/collections/#{@id()}.#{format}"

    level: => -1

    performHierarchyChanges: (site, changes) =>

  class window.Collection extends CollectionBase
    constructor: (data) ->
      super(data)
      @layers = ko.observableArray()
      @fields = ko.observableArray()
      @checked = ko.observable true
      @fieldsInitialized = false

      @groupByOptions = ko.computed => [window.model.defaultGroupBy].concat(@fields().filter((f) -> f.kind() == 'hierarchy'))

    isSearch: => false

    sitesUrl: -> "/collections/#{@id()}/sites.json"

    fetchLocation: => $.get "/collections/#{@id()}.json", {}, (data) =>
      @position(data)
      @updatedAt(data.updated_at)

  class window.CollectionDecorator extends CollectionBase
    constructor: (collection) ->
      @collection = collection

      @id = ko.observable collection.id()
      @name = ko.observable collection.name()
      @layers = collection.layers
      @fields = collection.fields
      @fieldsInitialized = collection.fieldsInitialized
      @groupByOptions = collection.groupByOptions

      @initSites()

      @constructorLocation(lat: collection.lat(), lng: collection.lng())

    createSite: (site) => new Site(@collection, site)

    # These two methods are needed to be forwarded when editing sites inside a search
    updatedAt: (value) => @collection.updatedAt(value)
    fetchLocation: => @collection.fetchLocation()

  # A collection that is filtered by a search result
  class window.CollectionSearch extends CollectionDecorator
    constructor: (collection, search, filters, sort, sortDirection) ->
      super(collection)

      @search = search
      @filters = filters
      @sort = sort
      @sortDirection = sortDirection
      @hasDateFilter = ko.computed =>
        for filter in @filters
          return true if filter.isDateFilter()
        false

    isSearch: => true

    sitesUrl: =>
      "/collections/#{@id()}/search.json?#{$.param @queryParams()}"

    queryParams: =>
      q = {}
      q.search = @search if @search
      if @sort
        q.sort = @sort
        q.sort_direction = if @sortDirection then 'asc' else 'desc'
      filter.setQueryParams(q) for filter in @filters
      q

    link: (format) => "/api/collections/#{@id()}.#{format}?#{$.param @queryParams()}"

  # A collection that groups the items by a hierarchy field
  class window.CollectionHierarchy extends CollectionDecorator
    constructor: (collection, field) ->
      super(collection)

      @field = field
      @hierarchyItemsMap = {}
      @hierarchyItems = ko.observableArray $.map(field.hierarchy(), (x) => new HierarchyItem(@, field, x))

      @loadMoreSites()

    isSearch: => false

    sitesUrl: =>
      "/collections/#{@id()}/search.json?#{$.param @queryParams()}"

    queryParams: =>
      hierarchy_code: @field.code()

    addSite: (site, isNew = false) =>
      # We also add the site to the original collection
      # or to the hierarchy item where it belongs, if it's a new site
      if isNew
        @collection.addSite site

        if site.properties()[@field.code()]
          item = @hierarchyItemsMap[site.properties()[@field.code()]]
          item.addSite site if item && item.sitesPage > 1
        else
          super(site)
      else
        super(site)


    # The next two methods are invoked when a site's hierarchy field changes
    # value: we need to move it from the old node to the new node.
    performHierarchyChanges: (site, changes) =>
      for change in changes
        if change.field.code() == @field.code()
          @performHierarchyChange(site, change)

    performHierarchyChange: (site, change) =>
      if change.oldValue?
        item = @hierarchyItemsMap[change.oldValue]
        item.removeSite(site) if item
      else
        @removeSite(site)

      item = @hierarchyItemsMap[change.newValue]
      item.addSite(site) if item && item.sitesPage > 1

  # Used when grouping by a hierarchy field
  class window.HierarchyItem extends SitesContainer
    constructor: (collection, field, data, level = 0) ->
      @field = field

      collection.hierarchyItemsMap[data.id] = @

      @id = ko.observable(data.id)
      @name = ko.observable(data.name)
      @level = ko.observable(level)
      @selected = ko.observable(false)
      @hierarchyItems = if data.sub?
                          ko.observableArray($.map(data.sub, (x) => new HierarchyItem(collection, @field, x, level + 1)))
                        else
                          ko.observableArray()

      @initSites()

    sitesUrl: =>
      "/collections/#{window.model.currentCollection().id()}/search.json?#{$.param @queryParams()}"

    queryParams: =>
      hierarchy_code: @field.code()
      hierarchy_value: @id()

    createSite: (site) => new Site(window.model.currentCollection().collection, site)

  class window.Site extends Locatable
    constructor: (collection, data) ->
      super(data)

      @collection = collection
      @selected = ko.observable()
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @properties = ko.observable data?.properties
      @updatedAt = ko.observable(data.updated_at)
      @updatedAtTimeago = ko.computed => if @updatedAt() then $.timeago(@updatedAt()) else ''
      @editingName = ko.observable(false)
      @editingLocation = ko.observable(false)
      @locationText = ko.computed
        read: => (Math.round(@lat() * 100000) / 100000) + ', ' + (Math.round(@lng() * 100000) / 100000)
        write: (value) => @locationTextTemp = value
        owner: @
      @locationTextTemp = @locationText()
      @valid = ko.computed => @hasName()
      @highlightedName = ko.computed => window.model.highlightSearch(@name())
      @inEditMode = ko.observable(false)

    hasLocation: => @position()

    hasName: => $.trim(@name()).length > 0

    propertyValue: (field) =>
      value = @properties()[field.code()]
      field.valueUIFor(value)

    highlightedPropertyValue: (field) =>
      window.model.highlightSearch(@propertyValue(field))

    fetchLocation: =>
      $.get "/sites/#{@id()}.json", {}, (data) =>
        @position(data)
        @updatedAt(data.updated_at)
      @collection.fetchLocation()

    updateProperty: (code, value) =>
      field = @collection.findFieldByCode(code)
      if field.kind() == 'hierarchy' && window.model.currentCollection()
        window.model.currentCollection().performHierarchyChanges(@, [{field: field, oldValue: @properties()[code], newValue: value}])

      @properties()[code] = value

      $.post "/sites/#{@id()}/update_property.json", {code: code, value: value}, (data) =>
        @propagateUpdatedAt(data.updated_at)

    copyPropertiesFromCollection: (collection) =>
      oldProperties = @properties()

      hierarchyChanges = []

      @properties({})
      for field in collection.fields()
        if field.kind() == 'hierarchy' && @id()
          hierarchyChanges.push({field: field, oldValue: oldProperties[field.code()], newValue: field.value()})

        if field.value()
          @properties()[field.code()] = field.value()
        else
          delete @properties()[field.code()]

      if window.model.currentCollection()
        window.model.currentCollection().performHierarchyChanges(@, hierarchyChanges)

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
        $.post "/collections/#{@collection.id()}/sites/#{@id()}.json", data, callback_with_updated_at
      else
        $.post "/collections/#{@collection.id()}/sites", data, callback_with_updated_at

    propagateUpdatedAt: (value) =>
      @updatedAt(value)
      @collection.propagateUpdatedAt(value)

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
          @collection.fetchLocation()
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
      return if @inEditMode() || @nameBeforeGeolocateName == @name()

      @nameBeforeGeolocateName = @name()
      @parseLocation text: @fullName(), success: (position) =>
        @position(position)
        @marker.setPosition(position)
        @panToPosition()

    fullName: => "#{@collection.name()}, #{@name()}"

    parseLocation: (options) =>
      text = options.text || @locationTextTemp
      if match = text.match(/^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$/)
        options.success(new google.maps.LatLng(parseFloat(match[1]), parseFloat(match[2])))
      else
        window.model.geocoder.geocode { 'address': text}, (results, status) =>
          if results.length > 0
            options.success(results[0].geometry.location)
          else
            options.failure(@originalLocation) if options.failure?

    exitLocation: =>
      @endEditLocationInMap(@originalLocation)
      delete @originalLocation

    startEditMode: =>
      # Keep the original values, in case the user cancels
      @originalName = @name()
      @originalPosition = @position()
      for field in window.model.currentCollection().fields()
        field.editing(false)
        field.originalValue = field.value()

      @inEditMode(true)
      @startEditLocationInMap()

    exitEditMode: (saved) =>
      @inEditMode(false)
      @endEditLocationInMap(if saved then @position() else @originalLocation)

      # Restore original name and position if not saved
      unless saved
        @name(@originalName)
        @position(@originalPosition)
        delete @originalName
        delete @originalPosition

      # Expand fields, clear filters (select_many),
      # and restore original field values if not saved
      for field in window.model.currentCollection().fields()
        field.expanded(false)
        field.filter('')

        unless saved
          field.value(field.originalValue)
          delete field.originalValue

    createMarker: (drop = false) =>
      @deleteMarker()

      draggable = @editingLocation() || !@id()
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

    toJSON: =>
      json =
        id: @id()
        name: @name()
      json.lat = @lat() if @lat()
      json.lng = @lng() if @lng()
      json.properties = @properties() if @properties()
      json

)
