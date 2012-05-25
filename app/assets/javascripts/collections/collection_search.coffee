#= require collections/collection_decorator

onCollections ->

  # A collection that is filtered by a search result
  class @CollectionSearch extends CollectionDecorator
    constructor: (collection, search, filters, sort, sortDirection) ->
      super(collection)

      @search = search
      @filters = filters
      @sort = sort
      @sortDirection = sortDirection
      @hasDateFilter = ko.computed =>
        for filter in @filters
          return true if filter.isDateFilter()
        false

    isSearch: => true

    addSite: (site, isNew = false) =>
      @collection.addSite site if isNew
      super(site)

    sitesUrl: =>
      "/collections/#{@id()}/search.json?#{$.param @queryParams()}"

    queryParams: (api = false) =>
      @setQueryParams {}, api

    setQueryParams: (q, api = false) =>
      q.search = @search if @search
      if @sort
        if api
          field = @collection.findFieldByEsCode(@sort)
          q.sort = if field then field.code() else @sort
        else
          q.sort = @sort
        q.sort_direction = if @sortDirection then 'asc' else 'desc'
      filter.setQueryParams(q, api) for filter in @filters
      q

    link: (format) => "/api/collections/#{@id()}.#{format}?#{$.param @queryParams(true)}"
