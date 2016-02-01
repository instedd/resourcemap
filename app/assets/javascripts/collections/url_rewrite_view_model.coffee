onCollections ->

  class @UrlRewriteViewModel
    @rewriteUrl: (reloadSites = true) ->
      return if @processingURL
      query = {}

      # Append collection parameters (search, filters, hierarchy, etc.)
      @currentCollection().setQueryParams(query) if @currentCollection()

      # Append selected site or editing site, if any
      if @editingSite()
        query.editing_site = @editingSite().id()
        query.collection_id = @editingSite().collection.id
      else if @selectedSite()
        query.selected_site = @selectedSite().id()
        query.selected_collection = @selectedSite().collection.id
        query.collection_id = @selectedSite().collection.id
      else if @currentCollection()
        query.collection_id = @currentCollection().id

      # Append map center and zoom
      if @map
        center = @map.getCenter()
        if center
          query.lat = center.lat()
          query.lng = center.lng()
          query.z = @map.getZoom()

      # Append map/table view mode
      query._table = true unless @showingMap()

      location = document.createElement 'a'
      location.href = window.location
      location.search = $.param query
      History.pushState null, null, location.href

      @reloadMapSites() if reloadSites


    @processURL: ->
      selectedSiteId = null
      selectedCollectionId = null
      editingSiteId = null
      showTable = false
      groupBy = null

      collectionId = $.url().param('collection_id')

      if collectionId and not @currentCollection()
        @enterCollection collectionId
        return

      @queryParams = $.url().param()
      for key of @queryParams
        value = @queryParams[key]
        switch key
          when 'lat', 'lng', 'z', 'collection_id'
            continue
          when 'search'
            @search(value)
          when 'updated_since'
            switch value
              when 'last_hour' then @filterByLastHour()
              when 'last_day' then @filterByLastDay()
              when 'last_week' then @filterByLastWeek()
              when 'last_month' then @filterByLastMonth()
          when 'location_missing'
            @filterByLocationMissing()
          when 'selected_site'
            selectedSiteId = parseInt(value)
          when 'selected_collection'
            selectedCollectionId = parseInt(value)
          when 'editing_site'
            editingSiteId = parseInt(value)
          when '_table'
            showTable = true
          when 'hierarchy_code'
            groupBy = value
          when 'sort'
            @sort(value)
          when 'sort_direction'
            @sortDirection(value == 'asc')
          else
            continue if not @currentCollection()
            @expandedRefineProperty(key)

            if value.length >= 2 && value[0] in ['>', '<', '~'] && value[1] == '='
              @expandedRefinePropertyOperator(value.substring(0, 2))
              @expandedRefinePropertyValue(value.substring(2))
            else if value[0] in ['=', '>', '<']
              @expandedRefinePropertyOperator(value[0])
              @expandedRefinePropertyValue(value.substring(1))
            else
              @expandedRefinePropertyValue(value)

            if key == 'sitename'
              @filterByName()
            else
              @filterByProperty()

      @ignorePerformSearchOrHierarchy = false
      @performSearchOrHierarchy()

      if showTable
        @showTable()
      else
        @initMap()

      @selectSiteFromId(selectedSiteId, selectedCollectionId) if selectedSiteId
      @editSiteFromMarker(editingSiteId, collectionId) if editingSiteId
      @groupBy(@currentCollection().findFieldByEsCode(groupBy)) if groupBy && @currentCollection()

      @processingURL = false

      @rewriteUrl()
