onCollections ->

  class @SammyViewModel
    @initSammy: ->
      self = this

      Sammy( ->
        @get '#:collection', ->
          rewriting = self.rewritingUrl
          self.rewritingUrl = false
          return if rewriting

          collection = self.findCollectionById parseInt(this.params.collection)
          self.currentCollection collection
          self.unselectSite() if self.selectedSite()
          collection.loadMoreSites() if collection.sitesPage == 1

          initialized = self.initMap()
          collection.panToPosition(true) unless initialized

          collection.fetchFields =>
            self.refreshTimeago()
            self.makeFixedHeaderTable()
            self.rewriteUrl()
        @get '#/', ->
          rewriting = self.rewritingUrl
          self.rewritingUrl = false
          return if rewriting

          self.currentCollection(null)
          self.unselectSite() if self.selectedSite()
          self.search('')
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
