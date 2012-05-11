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
          else
            key = key.substring(1) if key[0] == '@'
            @expandedRefineProperty(key)

            if value.length >= 2 && (value[0] == '>' || value[0] == '<') && value[1] == '='
              @expandedRefinePropertyOperator(value.substring(0, 2))
              @expandedRefinePropertyValue(value.substring(2))
            else if value[0] == '=' || value[0] == '>' || value[0] == '<'
              @expandedRefinePropertyOperator(value[0])
              @expandedRefinePropertyValue(value.substring(1))
            else
              @expandedRefinePropertyValue(value)
            @filterByProperty()

      @ignorePerformSearchOrHierarchy = false
      @performSearchOrHierarchy()
