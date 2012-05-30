onCollections ->

  class @SitesViewModel
    @constructorSitesViewModel: ->
      @editingSite = ko.observable()
      @selectedSite = ko.observable()
      @loadingSite = ko.observable(false)
      @newOrEditSite = ko.computed => if @editingSite() && (!@editingSite().id() || @editingSite().inEditMode()) then @editingSite() else null
      @showSite = ko.computed => if @editingSite()?.id() && !@editingSite().inEditMode() then @editingSite() else null
      @markers = {}

    @editingSiteLocation: ->
      @editingSite() && (!@editingSite().id() || @editingSite().inEditMode() || @editingSite().editingLocation())

    @createSite: ->
      @goBackToTable = true unless @showingMap()
      @showMap =>
        pos = @originalSiteLocation = @map.getCenter()
        site = new Site(@currentCollection(), lat: pos.lat(), lng: pos.lng())
        site.copyPropertiesToCollection(@currentCollection())
        @unselectSite()
        @editingSite site
        @editingSite().startEditLocationInMap()

    @editSite: (site) ->
      @goBackToTable = true unless @showingMap()
      @showMap =>
        site.copyPropertiesToCollection(site.collection)
        if @selectedSite() && @selectedSite().id() == site.id()
          @unselectSite()
          @selectSite(site)
        else
          @selectSite(site)
        @editingSite(site)
        @rewriteUrl()

    @selectSiteFromId: (siteId) ->
      site = @siteIds[siteId]
      if site
        @selectSite site
      else
        @loadingSite(true)
        $.get "/sites/#{siteId}.json", {}, (data) =>
          @loadingSite(false)
          collection = window.model.findCollectionById(data.collection_id)
          site = new Site(collection, data)
          site = collection.addSite(site)
          @selectSite site

    @editSiteFromMarker: (siteId) ->
      @exitSite() if @editingSite()

      # Remove name popup if any
      window.model.markers[siteId].popup.remove() if window.model.markers[siteId]?.popup

      site = @siteIds[siteId]
      if site
        @editSite site
      else
        @loadingSite(true)
        if @selectedSite() && @selectedSite().marker
          @setMarkerIcon @selectedSite().marker, 'active'
        $.get "/sites/#{siteId}.json", {}, (data) =>
          @loadingSite(false)
          collection = window.model.findCollectionById(data.collection_id)
          site = new Site(collection, data)
          @editSite site

    @saveSite: ->
      return unless @editingSite().valid()

      callback = (data) =>
        unless @editingSite().id()
          @editingSite().id(data.id)
          @editingSite().idWithPrefix(data.id_with_prefix)
          @currentCollection().addSite(@editingSite(), true)

        @editingSite().updatedAt(data.updated_at)

        @editingSite().position(data)
        @currentCollection().fetchLocation()

        if @editingSite().inEditMode()
          @editingSite().exitEditMode(true)
        else
          @editingSite().deleteMarker()
          @exitSite()

      @editingSite().copyPropertiesFromCollection(@currentCollection())

      @editingSite().post @editingSite().toJSON(), callback

    @exitSite: ->
      field.editing(false) for field in @currentCollection().fields()
      if @editingSite().inEditMode()
        @editingSite().exitEditMode()
      else
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
      @rewriteUrl()

    @deleteSite: ->
      if confirm("Are you sure you want to delete #{@editingSite().name()}?")
        @unselectSite()
        @currentCollection().removeSite(@editingSite())
        $.post "/sites/#{@editingSite().id()}", {_method: 'delete'}, =>
          @currentCollection().fetchLocation()
          @editingSite().deleteMarker()
          @exitSite()
          @reloadMapSites() if @showingMap()

    @selectSite: (site) ->
      if @showingMap()
        if @selectedSite()
          if @selectedSite().marker
            # This is to prevent flicker: when the map reloads, we try to reuse the old site marker
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

    @unselectSite: ->
      @selectSite(@selectedSite()) if @selectedSite()
