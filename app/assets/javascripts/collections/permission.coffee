onCollections ->

  class @Permission
    constructor: (data) ->
      @allSites = data?.all_sites ? true

      @someSites = data?.some_sites.map (x) -> parseInt x.id

    canAccess: (siteId) ->
      @allSites or @someSites.indexOf(siteId) > -1
