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
      @highlightedName = ko.computed => window.model.highlightSearch(@name())
      @highlightedLat = ko.computed => window.model.highlightSearch(@safe_lat())
      @highlightedLng = ko.computed => window.model.highlightSearch(@safe_lng())
      @inEditMode = ko.observable(false)
      # Default permission for the collection. If this site has custom permission, these will be updated in updatePermission method
      @nameWriteable = (collection.namePermission == 'update')
      @locationWriteable = (collection.locationPermission == 'update')

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

      $.ajax({
        type: "POST",
        url: "/sites/#{@id()}/update_property.json",
        data: {es_code: esCode, value: value},
        success: ((data) =>
          field.errorMessage("")
          @propagateUpdatedAt(data.updated_at)
          window.model.updateSitesInfo()),
        global: false
      })
      .fail((data) =>
        try
          responseMessage = JSON.parse(data.responseText)
          if data.status == 422 && responseMessage && responseMessage.error_message
            field.errorMessage(responseMessage.error_message)
          else
            $.handleAjaxError(data)
        catch error
          $.handleAjaxError(data))

    copyPropertiesFromCollection: (collection) =>
      oldProperties = @properties()

      hierarchyChanges = []

      @properties({})
      for field in collection.fields()
        if field.kind == 'hierarchy' && @id()
          hierarchyChanges.push({field: field, oldValue: oldProperties[field.esCode], newValue: field.value()})

        value = field.value()
        @properties()[field.esCode] = value

      if window.model.currentCollection()
        window.model.currentCollection().performHierarchyChanges(@, hierarchyChanges)

    copyPropertiesToCollection: (collection) =>
      collection.fetchFields =>
        collection.clearFieldValues()
        if @properties()
          for field in collection.fields()
            value = @properties()[field.esCode]
            field.setValueFromSite(value)

    update_site: (json, callback, failed_callback = null) =>
      data = {site: JSON.stringify json}
      $.ajax({
          type: "POST",
          url: "/collections/#{@collection.id}/sites/#{@id()}/partial_update.json",
          data: data,
          success: ((data) =>
            @clearFieldErrors()
            @propagateUpdatedAt(data.updated_at)
            callback(data) if callback && typeof(callback) == 'function' )
          global: false
        }).fail((data) =>
          failed_callback() if failed_callback != null
          if @showFieldErrors(data)
            $(".tablescroll").animate({
              scrollTop: $('.error label').position().top + $(".tablescroll").scrollTop() - 60
            }, 2000))

    create_site: (json, callback, failed_callback = null) =>
      data = {site: JSON.stringify json}
      $.ajax({
          type: "POST",
          url: "/collections/#{@collection.id}/sites",
          data: data,
          success: ((data) =>
            @clearFieldErrors()
            @propagateUpdatedAt(data.updated_at)
            @id(data.id)
            @idWithPrefix(data.id_with_prefix)

            notice = Jed.sprintf(__("Site '%s' successfully created"), @name())

            $.status.showNotice notice, 2000
            callback(data) if callback && typeof(callback) == 'function' )
          global: false
        }).fail((data) =>
          failed_callback() if failed_callback != null
          @showFieldErrors(data)
        )

    clearFieldErrors: =>
      @collection.nameFieldError(null)
      for field in @collection.fields()
        field.errorMessage("")

    showFieldErrors: (data) =>
      try
        @clearFieldErrors()
        errors = JSON.parse(data.responseText)
        nameErrors = errors.name
        propertyErrors = errors.properties
        if data.status == 422 && (nameErrors || propertyErrors)
          if nameErrors
            for value in nameErrors
              @collection.nameFieldError("Name #{value}")
          if propertyErrors
            for prop in propertyErrors
              for es_code, value of prop
                f = @collection.findFieldByEsCode(es_code)
                f.errorMessage(value)
          true
        else
          $.handleAjaxError(data)
          false
      catch error
          $.handleAjaxError(data)
          false

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
        @update_site name: @name()
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
        @update_site lat: @lat(), lng: @lng(), (data) =>
          @collection.fetchLocation()
          @endEditLocationInMap(@extractPosition data)
          window.model.updateSitesInfo()

      @parseLocation
        success: (position) => @position(position); save()
        failure: (position) => @position(position); @endEditLocationInMap(position)

    extractPosition: (from) ->
      if from.lat || from.lng then { lat: from.lat, lng: from.lng } else null

    newLocationKeyPress: (site, event) =>
      switch event.keyCode
        when 13
          if $.trim(@locationTextTemp).length == 0
            @position(null)
            return true
          else
            @moveLocation()
            false
        else
          true

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
      else if match = text.match(/^\s*(\d+(?:\.\d+)?)\s*(N|S)\s*,\s*(\d+(?:\.\d+)?)\s*(E|W)\s*$/i)
        lat = if match[2].match(/n/i) then parseFloat(match[1]) else -parseFloat(match[1])
        lng = if match[4].match(/e/i) then parseFloat(match[3]) else -parseFloat(match[3])
        options.success(new google.maps.LatLng(lat, lng))
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
        field.onEnteredEditMode()

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

    diff: =>
      return {} unless @inEditMode()
      diff = {}
      diff.name = @name() if @originalName && @originalName != @name()
      diff.lat = @lat() if @originalPosition && @originalPosition.lat() != @position().lat()
      diff.lng = @lng() if @originalPosition && @originalPosition.lng() != @position().lng()
      diff.properties = @propertiesDiff() unless _.isEqual(@propertiesDiff(), {})
      diff

    propertiesDiff: =>
      return {} unless @inEditMode()
      diff = {}
      for field in window.model.currentCollection().fields()
        diff[field.esCode] = field.value() if field.hasChanged()
      diff

    # Ary: I have no idea why, but without this here toJSON() doesn't work
    # in Firefox. It seems a problem with the bindings caused by the fat arrow
    # (=>), but I couldn't figure it out. This "solves" it for now.
    dummy: =>
