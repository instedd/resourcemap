onCollections ->

  class @UrlRewriteViewModel
    @rewriteUrl: ->
      return if @rewritingUrl

      @rewritingUrl = true

      hash = ""
      query = {}

      if @currentCollection()
        hash = "##{@currentCollection().id}"
      else
        hash = "#/"

      # Append collection parameters (search, filters, hierarchy, etc.)
      @currentCollection().setQueryParams(query) if @currentCollection()

      # Append selected site or editing site, if any
      if @editingSite()
        query.editing_site = @editingSite().id()
        query.editing_collection = @editingSite().collection.id
      else if @selectedSite()
        query.selected_site = @selectedSite().id()
        query.selected_collection = @selectedSite().collection.id

      # Append map center and zoom
      if @map
        center = @map.getCenter()
        if center
          query.lat = center.lat()
          query.lng = center.lng()
          query.z = @map.getZoom()

      # Append map/table view mode
      query._table = true unless @showingMap()

      params = $.param query
      hash += "?#{params}" if params.length > 0

      if window.location.hash == hash
        @rewritingUrl = false
      else
        window.location.hash = hash

      @reloadMapSites()


    @processQueryParams: ->
      @ignorePerformSearchOrHierarchy = true
      selectedSiteId = null
      selectedCollectionId = null
      editingSiteId = null
      editingCollectionId = null
      showTable = false
      groupBy = null

      for key in @queryParams.keys(true)
        value = @queryParams[key]
        switch key
          when 'collection', 'lat', 'lng', 'z'
            continue
          when 'search'
            @search(value)
          when 'updated_since'
            switch value
              when 'last_hour' then @filterByLastHour()
              when 'last_day' then @filterByLastDay()
              when 'last_week' then @filterByLastWeek()
              when 'last_month' then @filterByLastMonth()
          when 'selected_site'
            selectedSiteId = parseInt(value)
          when 'selected_collection'
            selectedCollectionId = parseInt(value)
          when 'editing_site'
            editingSiteId = parseInt(value)
          when 'editing_collection'
            editingCollectionId = parseInt(value)
          when '_table'
            showTable = true
          when 'hierarchy_code'
            groupBy = value
          when 'sort'
            @sort(value)
          when 'sort_direction'
            @sortDirection(value == 'asc')
          else
            @expandedRefineProperty(key)

            if value.length >= 2 && value[0] in ['>', '<', '~'] && value[1] == '='
              @expandedRefinePropertyOperator(value.substring(0, 2))
              @expandedRefinePropertyValue(value.substring(2))
            else if value[0] in ['=', '>', '<']
              @expandedRefinePropertyOperator(value[0])
              @expandedRefinePropertyValue(value.substring(1))
            else
              @expandedRefinePropertyValue(value)
            @filterByProperty()

      @ignorePerformSearchOrHierarchy = false
      @performSearchOrHierarchy()

      @showTable() if showTable
      @selectSiteFromId(selectedSiteId, selectedCollectionId) if selectedSiteId
      @editSiteFromMarker(editingSiteId, editingCollectionId) if editingSiteId
      @groupBy(@currentCollection().findFieldByEsCode(groupBy)) if groupBy && @currentCollection()
