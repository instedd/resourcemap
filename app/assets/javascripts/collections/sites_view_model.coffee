onCollections ->

  class @SitesViewModel
    @constructor: ->
      @editingSite = ko.observable()
      @selectedSite = ko.observable()
      @selectedHierarchy = ko.observable()
      @loadingSite = ko.observable(false)
      @savingSite = ko.observable(false)
      @newOrEditSite = ko.computed => if @editingSite() && (!@editingSite().id() || @editingSite().inEditMode()) then @editingSite() else null
      @showSite = ko.computed => if @editingSite()?.id() && !@editingSite().inEditMode() then @editingSite() else null
      @expandLeftColumn = ko.computed =>
        @editingSite() && (!@editingSite().id() || @editingSite().inEditMode())
      window.markers = @markers = {}

      # Make sure to resize the map and keep its center when the left column's width changes
      @expandLeftColumn.subscribe @refreshMapResize

    @loadBreadCrumb: ->
      params = {}
      if @selectedSite()
        params["site_name"] = @selectedSite().name() # send the site's name to avoid having to make a server side query for it
        params["site_id"] = @selectedSite().id()
      params["collection_id"] = @currentCollection().id if @currentCollection()

      $('.BreadCrumb').load("/collections/breadcrumbs", params)

    @editingSiteLocation: ->
      @editingSite() && (!@editingSite().id() || @editingSite().inEditMode() || @editingSite().editingLocation())

    @createSite: ->
      @goBackToTable = true unless @showingMap()
      @showMap =>
        pos = @originalSiteLocation = @map.getCenter()
        site = new Site(@currentCollection(), lat: pos.lat(), lng: pos.lng())
        site.copyPropertiesToCollection(@currentCollection())

        if window.model.newSiteProperties
          for esCode, value of window.model.newSiteProperties
            field = @currentCollection().findFieldByEsCode esCode
            field.defaultValue(value) if field && field.kind == 'identifier'
            field.setValueFromSite(value) if field

        # I can't figure out why the screen scroll down after this.
        # So we do this workaround: remember the windows' scroll top
        # and later restore that value
        oldScrollTop = $(window).scrollTop()

        @unselectSite()
        @editingSite site
        @editingSite().startEditLocationInMap()

        $(window).scrollTop(oldScrollTop)

        window.model.initDatePicker()
        window.model.initAutocomplete()

    @editSite: (site) ->
      @goBackToTable = true unless @showingMap()
      @showMap =>
        site.copyPropertiesToCollection(site.collection)
        if @selectedSite() && @selectedSite().id() == site.id()
          @unselectSite()

        unless @currentCollection()
          @currentCollection(site.collection)
        site.collection.updatePermission site, => @editingSite(site)
        @selectSite(site)
        siteSearchCount = @currentCollection().siteSearchCount()
        @currentCollection(site.collection)
        @currentCollection().siteSearchCount(siteSearchCount)

        @loadBreadCrumb()

    @editSiteFromId: (siteId, collectionId) ->
      site = @siteIds[siteId]
      if site
        @editSite site
      else
        @loadingSite(true)
        $.get "/collections/#{collectionId}/sites/#{siteId}.json", {}, (data) =>
          @loadingSite(false)
          collection = window.model.findCollectionById(collectionId)
          site = new Site(collection, data)
          site = collection.addSite(site)
          @editSite site

    @selectSiteFromId: (siteId, collectionId) ->
      site = @siteIds[siteId]
      if site
        @selectSite site
      else
        @loadingSite(true)
        $.get "/collections/#{collectionId}/sites/#{siteId}.json", {}, (data) =>
          @loadingSite(false)
          collection = window.model.findCollectionById(collectionId)
          # Data will be empty if site is not found
          if !$.isEmptyObject(data)
            site = new Site(collection, data)
            site = collection.addSite(site)
            @selectSite site
          else
            @enterCollection(collection)

    @editSiteFromMarker: (siteId, collectionId) ->
      @exitSite() if @editingSite()
      # Remove name popup if any
      window.model.markers[siteId].popup.remove() if window.model.markers[siteId]?.popup
      if typeof collectionId == 'string'
        collectionId = parseInt(collectionId)

      site = @siteIds[siteId]
      if site
        @editSite site
      else
        @loadingSite(true)
        if @selectedSite() && @selectedSite().marker
          @setMarkerIcon @selectedSite().marker, 'active'
        $.get "/collections/#{collectionId}/sites/#{siteId}.json", {}, (data) =>
          @loadingSite(false)
          collection = window.model.findCollectionById(collectionId)
          site = new Site(collection, data)
          @editSite site

    @saveSite: ->
      return if @savingSite()
      @savingSite(true)
      callback = (data) =>
        @currentCollection().reloadSites()

        @editingSite().updatedAt(data.updated_at)

        @editingSite().position(data)
        @currentCollection().fetchLocation()

        if @editingSite().inEditMode()
          @editingSite().exitEditMode(true)
        else
          @editingSite().deleteMarker()
          @exitSite()

        @savingSite(false)

      failed_callback = =>
        @savingSite(false)

        window.model.updateSitesInfo()

      @editingSite().copyPropertiesFromCollection(@currentCollection())

      if @editingSite().id()
        @editingSite().update_site(@editingSite().diff(), callback, failed_callback)
      else
        @editingSite().create_site(@editingSite().toJSON(), callback, failed_callback)

    @exitSite: ->
      if !@editingSite()?.inEditMode()
        @performSearchOrHierarchy()

      field.exitEditing() for field in @currentCollection().fields()
      if @editingSite()?.inEditMode()
        @editingSite().exitEditMode()
      if @editingSite()
        # Unselect site if it's not on the tree
        @editingSite().editingLocation(false)
        @editingSite().deleteMarker() unless @editingSite().id()
        @editingSite(null)
        window.model.setAllMarkersActive()
        if @goBackToTable
          @showTable()
          delete @goBackToTable
        else
          @reloadMapSites()

      @loadBreadCrumb()
      @rewriteUrl()

      # Return undefined because otherwise some browsers (i.e. Miss Firefox)
      # would render the Object returned when called from a 'javascript:___'
      # value in an href (and this is done in the breadcrumb links).
      undefined

    @deleteSite: ->
      confirmation = Jed.sprintf(__("Are you sure you want to delete %s?"), @editingSite().name())
      if confirm(confirmation)
        @unselectSite()
        @currentCollection().removeSite(@editingSite())
        $.post "/sites/#{@editingSite().id()}", {collection_id: @currentCollection().id, _method: 'delete'}, =>
          @currentCollection().fetchLocation()
          @editingSite().deleteMarker()
          @exitSite()
          @reloadMapSites() if @showingMap()
          window.model.updateSitesInfo()

    @selectSite: (site) ->
      if @selectedHierarchy()
          @selectedHierarchy(null)
      if @showingMap()
        if @selectedSite()
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
              @selectedSite().createMarker()
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

      @rewriteUrl()


    @selectHierarchy: (hierarchy) ->
      if @selectedSite()
        @unselectSite()
      @selectedHierarchy(hierarchy)

    @unselectSite: ->
      @selectSite(@selectedSite()) if @selectedSite()
