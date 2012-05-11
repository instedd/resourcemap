onCollections ->

  class @UrlRewriteViewModel
    @rewriteUrl: ->
      @rewritingUrl = true

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

      # Append map center and zoom
      center = @map.getCenter()
      if center
        query.lat = center.lat()
        query.lng = center.lng()
        query.z = @map.getZoom()

      params = $.param query
      hash += "?#{params}" if params.length > 0

      if window.location.hash == hash
        @rewritingUrl = false
      else
        window.location.hash = hash
