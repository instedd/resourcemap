#= require module
#= require collections/locatable

onCollections ->

  class @Site extends Module
    @include Locatable

    constructor: (collection, data) ->
      @constructorLocatable(data)

      @collection = collection
      @selected = ko.observable()
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @alert = ko.observable data?.alert
      @icon = ko.observable data?.icon
      @idWithPrefix = ko.observable data?.id_with_prefix
      @properties = ko.observable data?.properties
      @updatedAt = ko.observable(data.updated_at)
      @updatedAtTimeago = ko.computed => if @updatedAt() then $.timeago(@updatedAt()) else ''
      @editingName = ko.observable(false)
      @editingLocation = ko.observable(false)
      @locationText = ko.computed
        read: =>
          if @hasLocation()
            (Math.round(@lat() * 100000) / 100000) + ', ' + (Math.round(@lng() * 100000) / 100000)
          else
            ''
        write: (value) => @locationTextTemp = value
        owner: @
      @locationTextTemp = @locationText()
      @valid = ko.computed => @hasName()
      @highlightedName = ko.computed => window.model.highlightSearch(@name())
      @inEditMode = ko.observable(false)

    hasLocation: => @position() != null

    hasName: => $.trim(@name()).length > 0

    propertyValue: (field) =>
      value = @properties()[field.esCode]
      field.valueUIFor(value)

    highlightedPropertyValue: (field) =>
      window.model.highlightSearch(@propertyValue(field))

    fetchLocation: =>
      $.get "/collections/#{@collection.id}/sites/#{@id()}.json", {}, (data) =>
        @position(data)
        @updatedAt(data.updated_at)
      @collection.fetchLocation()

    updateProperty: (esCode, value) =>
      field = @collection.findFieldByEsCode(esCode)
      if field.showInGroupBy && window.model.currentCollection()
        window.model.currentCollection().performHierarchyChanges(@, [{field: field, oldValue: @properties()[esCode], newValue: value}])

      @properties()[esCode] = value

      $.post "/sites/#{@id()}/update_property.json", {es_code: esCode, value: value}, (data) =>
        @propagateUpdatedAt(data.updated_at)

    copyPropertiesFromCollection: (collection) =>
      oldProperties = @properties()

      hierarchyChanges = []

      @properties({})
      for field in collection.fields()
        if field.kind == 'hierarchy' && @id()
          hierarchyChanges.push({field: field, oldValue: oldProperties[field.esCode], newValue: field.value()})

        if field.value()
          @properties()[field.esCode] = field.value()
        else
          delete @properties()[field.esCode]

      if window.model.currentCollection()
        window.model.currentCollection().performHierarchyChanges(@, hierarchyChanges)

    copyPropertiesToCollection: (collection) =>
      collection.fetchFields =>
        collection.clearFieldValues()
        if @properties()
          for field in collection.fields()
            value = @properties()[field.esCode]
            field.value(value)

    post: (json, callback) =>
      callback_with_updated_at = (data) =>
        @propagateUpdatedAt(data.updated_at)
        callback(data) if callback && typeof(callback) == 'function'

      data = {site: json}
      if @id()
        data._method = 'put'
        $.post "/collections/#{@collection.id}/sites/#{@id()}.json", data, callback_with_updated_at
      else
        $.post "/collections/#{@collection.id}/sites", data, callback_with_updated_at

    propagateUpdatedAt: (value) =>
      @updatedAt(value)
      @collection.propagateUpdatedAt(value)

    editName: =>
      if !@collection.currentSnapshot
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
      if !@collection.currentSnapshot
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

    fullName: => "#{@collection.name}, #{@name()}"

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

      position =  @position() || window.model.map.getCenter()

      draggable = @editingLocation() || !@id()
      @marker = new google.maps.Marker
        map: window.model.map
        position: position
        animation: if drop || !@id() || !@position() then google.maps.Animation.DROP else null
        draggable: draggable
        icon: window.model.markerImageTarget
        shadow: window.model.markerImageTargetShadow
        zIndex: 2000000
      @marker.name = @name()
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

    # Ary: I have no idea why, but without this here toJSON() doesn't work
    # in Firefox. It seems a problem with the bindings caused by the fat arrow
    # (=>), but I couldn't figure it out. This "solves" it for now.
    dummy: =>
