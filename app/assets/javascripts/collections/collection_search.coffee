$(-> if $('#collections-main').length > 0

  # A collection that is filtered by a search result
  class window.CollectionSearch extends CollectionDecorator
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

    sitesUrl: =>
      "/collections/#{@id()}/search.json?#{$.param @queryParams()}"

    queryParams: =>
      q = {}
      q.search = @search if @search
      if @sort
        q.sort = @sort
        q.sort_direction = if @sortDirection then 'asc' else 'desc'
      filter.setQueryParams(q) for filter in @filters
      q

    link: (format) => "/api/collections/#{@id()}.#{format}?#{$.param @queryParams()}"

)
