onCollections ->

  class @UrlRewriteViewModel
    @rewriteUrl: ->
      @rewritingUrl = true
      @rewriteUrlCore()

    @rewriteUrlCore: ->
      hash = ""
      query = {}

      if @currentCollection()
        hash = "##{@currentCollection().id()}"
      else
        hash = "#/"

      # Append collection parameters (search, filters, hierarchy, etc.)
      @currentCollection().setQueryParams(query) if @currentCollection()

      # Append selected site or editing site, if any
      if @editingSite()
        query.editing_site = @editingSite().id()
      else if @selectedSite()
        query.selected_site = @selectedSite().id()

      # Append map bounds and zoom
      bounds = @map.getBounds()
      if bounds
        ne = bounds.getNorthEast()
        sw = bounds.getSouthWest()
        query.n = ne.lat()
        query.s = sw.lat()
        query.e = ne.lng()
        query.w = sw.lng()
        query.z = @map.getZoom()

      params = $.param query
      hash += "?#{params}" if params.length > 0

      window.location.hash = hash
