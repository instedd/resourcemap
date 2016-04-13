#= require module
#= require collections/site

onCollections ->

  class @SitesContainer
    @constructorSitesContainer: ->
      @expanded = ko.observable false
      @sites = ko.observableArray()
      @sitesPage = 1
      @hasMoreSites = ko.observable true
      @loadingSites = ko.observable true
      @siteSearchCount = ko.observable 0
      @siteIds = {}

    # Loads SITES_PER_PAGE sites more from the server, it there are more sites.
    @loadMoreSites: ->
      return unless @hasMoreSites()

      @loadingSites true
      # Fetch more sites. We fetch one more to know if we have more pages, but we discard that
      # extra element so the user always sees SITES_PER_PAGE elements.
      @fetchSites({offset: (@sitesPage - 1) * SITES_PER_PAGE, limit: SITES_PER_PAGE + 1}).then (data) =>
        sites = data.sites
        @siteSearchCount(data.total_count)
        @sitesPage += 1
        if sites.length == SITES_PER_PAGE + 1
          sites.pop()
        else
          @hasMoreSites false
        for site in sites
          @addSite @createSite(site)
        @loadingSites false
        window.model.refreshTimeago()

    @reloadSites: ->
      @loadingSites true
      @siteIds = {}
      @sites = ko.observableArray()
      @fetchSites({offset: 0, limit: (@sitesPage - 1) * SITES_PER_PAGE}).then (data) =>
        sites = data.sites
        @siteSearchCount(data.total_count)
        for site in sites
          @addSite @createSite(site)
        @loadingSites false
        window.model.refreshTimeago()

    @addSite: (site, isNew = false) ->
      return @siteIds[site.id()] if @siteIds[site.id()]

      # This check is because the selected site might be selected on the map,
      # but not in the tree. So we use that one instead of the one from the server,
      # and set its collection to ourself.
      if window.model.selectedSite()?.id() == site.id()
        site = window.model.selectedSite()
      else
        site = window.model.siteIds[site.id()] if window.model.siteIds[site.id()]

      @sites.push(site)

      window.model.siteIds[site.id()] = site
      @siteIds[site.id()] = site

      site

    @removeSite: (site) ->
      @sites.remove site
      @siteSearchCount(parseInt(@siteSearchCount()) - 1)
      delete window.model.siteIds[site.id()]
      delete @siteIds[site.id()]

    @toggleExpand: ->
      # Load more sites when we expand, but only the first time
      if !@expanded() && @hasMoreSites() && @sitesPage == 1
        @loadMoreSites()


      # Toggle select folder
      if !@expanded()
        window.model.selectHierarchy(this)
      else
        window.model.selectHierarchy(null)

      @expanded(!@expanded())
      window.model.reloadMapSites()

    @createSite: (site) -> new Site(@, site)
