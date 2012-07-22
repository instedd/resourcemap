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

          self.rewritingUrl = true

          collection = self.findCollectionById parseInt(this.params.collection)
          self.currentCollection collection
          self.unselectSite() if self.selectedSite()

          initialized = self.initMap()
          collection.panToPosition(true) unless initialized

          collection.fetchFields =>
            self.processQueryParams()
            self.refreshTimeago()
            self.makeFixedHeaderTable()

            self.rewritingUrl = false
            self.rewriteUrl()
        @get '#/', ->
          self.queryParams = @params

          rewriting = self.rewritingUrl
          self.rewritingUrl = false
          return if rewriting

          self.rewritingUrl = true

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

          self.rewritingUrl = false
          self.rewriteUrl()

        # This is a dummy route so we don't get errors from Sammy:
        # https://github.com/quirkey/sammy/issues/71
        @post '#/null', ->
      ).run()

