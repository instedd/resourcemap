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
      @icon = data?.icon ? 'default'
      @color = data?.color
      @idWithPrefix = ko.observable data?.id_with_prefix
      @properties = ko.observable data?.properties
      @updatedAt = ko.observable(data.updated_at)
      @updatedAtTimeago = ko.computed => if @updatedAt() then $.timeago(@updatedAt()) else ''
      @editingName = ko.observable(false)
      @editingLocation = ko.observable(false)
      @alert = ko.observable data?.alert
      @locationText = ko.computed
        read: =>
          if @hasLocation()
            (Math.round(@lat() * 1000000) / 1000000) + ', ' + (Math.round(@lng() * 1000000) / 1000000)
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

      $.post("/sites/#{@id()}/update_property.json", {es_code: esCode, value: value}, (data) =>
        if data.error_message
          #Validation failed
          field.error_message(data.error_message)
        else
          field.error_message("")
          @propagateUpdatedAt(data.updated_at))

    copyPropertiesFromCollection: (collection) =>
      oldProperties = @properties()

      hierarchyChanges = []

      @properties({})
      for field in collection.fields()
        if field.kind == 'hierarchy' && @id()
          hierarchyChanges.push({field: field, oldValue: oldProperties[field.esCode], newValue: field.value()})

        if field.value()
          value = field.value()

          @properties()[field.esCode] = value
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

      data = {site: JSON.stringify json}
      if @id()
        data._method = 'put'
        $.post "/collections/#{@collection.id}/sites/#{@id()}.json", data, callback_with_updated_at, 'json'
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
        @collection.reloadSites()
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
        @alertMarker.setMap null if @alertMarker
      @marker.setDraggable(true)
      window.model.setAllMarkersInactive()
      @panToPosition()

    endEditLocationInMap: (position) =>
      @editingLocation(false)
      @position(position)
      if @alertMarker
        @marker.setMap null
        delete @marker
        @alertMarker.setMap window.model.map
        @alertMarker.setData( id: @id(), collection_id: @collection.id, lat: @lat(), lng: @lng(), color: @color, icon: @icon, target: true)
      else
        @marker.setPosition(@position()) if position
        @marker.setDraggable false
        @deleteMarker() if !@position()

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
          @endEditLocationInMap(@extractPosition data)

      @parseLocation
        success: (position) => @position(position); save()
        failure: (position) => @position(position); @endEditLocationInMap(position)

    extractPosition: (from) ->
      if from.lat || from.lng then { lat: from.lat, lng: from.lng } else null

    newLocationKeyPress: (site, event) =>
      switch event.keyCode
        when 13
          @moveLocation()
          false
        else true

    moveLocation: =>
      callback = (position) =>
        @position(position)
        if position then @marker.setPosition(position)
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
      # Is text of the form 'num1.num1,num2.num2' after trimming whitespace?
      # If so, give me num1.num1 and num2.num2
      if match = text.match(/^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$/)
        options.success(new google.maps.LatLng(parseFloat(match[1]), parseFloat(match[2])))
      else
        if text == ''
          options.success(null)
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
      window.model.initDatePicker()
      window.model.initAutocomplete()

    exitEditMode: (saved) =>
      @collection.updatePermission @
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
        icon: window.model.markerImage 'resmap_' + @icon + '_target.png'
        zIndex: 2000000
      @marker.name = @name()
      @setupMarkerListener()
      window.model.setAllMarkersInactive() if draggable

    createAlert: () =>
      @deleteAlertMarker()
      @alertMarker = new Alert window.model.map, {id: @id(), collection_id: @collection.id, lat: @lat(), lng: @lng(), color: @color, icon: @icon, target: true}

    deleteMarker: (removeFromMap = true) =>
      return unless @marker
      @marker.setMap null if removeFromMap
      delete @marker
      @deleteMarkerListener() if removeFromMap

    deleteAlertMarker: (removeFromMap = true) =>
      return unless @alertMarker
      @alertMarker.setMap null if removeFromMap
      delete @alertMarker

    deleteMarkerListener: =>
      return unless @markerListener
      google.maps.event.removeListener @markerListener
      delete @markerListener

    setupMarkerListener: =>
      @markerListener = google.maps.event.addListener @marker, 'position_changed', =>
        @position(@marker.getPosition())
        @locationText("#{@marker.getPosition().lat()}, #{@marker.getPosition().lng()}")

    setupAlerMarkerListener: =>
      @alertMarkerListener = google.maps.event.addListener @alertMarker, 'position_changed', =>
        @position(@marker.getPosition())

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
