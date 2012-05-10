$(-> if $('#collections-main').length > 0

  class window.SammyViewModel
    @initSammy: ->
      self = this

      Sammy( ->
        @get '#:collection', ->
          # We don't want to fetch the collection if there's a search
          return if $.trim(self.search()).length > 0

          collection = self.findCollectionById parseInt(this.params.collection)
          self.currentCollection collection
          self.unselectSite() if self.selectedSite()
          collection.loadMoreSites() if collection.sitesPage == 1

          initialized = self.initMap()
          collection.panToPosition(true) unless initialized

          collection.fetchFields =>
            self.refreshTimeago()
            self.makeFixedHeaderTable()
        @get '#/', ->
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
      ).run()

)
