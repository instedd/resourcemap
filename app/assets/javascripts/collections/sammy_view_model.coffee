onCollections ->

  class @SammyViewModel
    @initSammy: ->
      self = this

      Sammy( ->
        @get '#:collection', ->
          self.queryParams = @params

          rewriting = self.rewritingUrl
          self.rewritingUrl = false
          return if rewriting

          collection = self.findCollectionById parseInt(this.params.collection)
          self.currentCollection collection
          self.unselectSite() if self.selectedSite()

          initialized = self.initMap()
          collection.panToPosition(true) unless initialized

          collection.fetchFields =>
            self.processQueryParams()
            self.refreshTimeago()
            self.makeFixedHeaderTable()
            self.rewriteUrl()
        @get '#/', ->
          self.queryParams = @params

          rewriting = self.rewritingUrl
          self.rewritingUrl = false
          return if rewriting

          self.currentCollection(null)
          self.unselectSite() if self.selectedSite()
          self.search('')
          self.lastSearch(null)
          self.filters([])
          self.sort(null)
          self.sortDirection(null)
          self.groupBy(self.defaultGroupBy)

          initialized = self.initMap()
          self.reloadMapSites() unless initialized
          self.refreshTimeago()
          self.makeFixedHeaderTable()

          self.rewriteUrl()

        # This is a dummy route so we don't get errors from Sammy:
        # https://github.com/quirkey/sammy/issues/71
        @post '#/null', ->
      ).run()

    @processQueryParams: ->
      @ignorePerformSearchOrHierarchy = true

      foundSearchOrHierarchy = false

      for key in @queryParams.keys(true)
        value = @queryParams[key]
        switch key
          when 'collection', 'lat', 'lng', 'z'
            continue
          when 'search'
            @search(value)
            foundSearchOrHierarchy = true
          when 'updated_since'
            switch value
              when 'last_hour' then @filters.push(new FilterByLastHour())
              when 'last_day' then @filters.push(new FilterByLastDay())
              when 'last_week' then @filters.push(new FilterByLastWeekHour())
              when 'last_month' then @filters.push(new FilterByLastMonthHour())
            foundSearchOrHierarchy = true

      @ignorePerformSearchOrHierarchy = false
      if foundSearchOrHierarchy
        @performSearchOrHierarchy()
      else
        @currentCollection().loadMoreSites() if @currentCollection() && @currentCollection().sitesPage == 1

