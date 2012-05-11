onCollections ->

  class @SearchViewModel
    @constructorSearchViewModel: ->
      @search = ko.observable('')
      @lastSearch = ko.observable(null)

      @inSearch = ko.computed => @currentCollection()?.isSearch()

    @performSearchOrHierarchy: ->
      return false unless @currentCollection()

      rootCollection = @currentCollection().collection ? @currentCollection()

      @unselectSite()

      if $.trim(@search()).length == 0 && @filters().length == 0 && !@sort()
        if @groupBy().code() == ''
          @currentCollection(rootCollection)
        else
          @currentCollection(new CollectionHierarchy(rootCollection, @groupBy()))
        @lastSearch(null)
      else
        @currentCollection(new CollectionSearch(rootCollection, @search(), @filters(), @sort(), @sortDirection()))
        @currentCollection().loadMoreSites()
        @lastSearch(@search())

      if @showingMap()
        @reloadMapSites()
      else
        window.adjustContainerSize()

      false

    @clearSearch: ->
      @search('')
      @performSearchOrHierarchy()

    @highlightSearch: (text) ->
      if @lastSearch()
        text = "#{text}"
        idx = text.toLowerCase().indexOf(@lastSearch().toLowerCase())
        if idx >= 0
          "#{text.substring(0, idx)}<b class=\"highlight\">#{text.substring(idx, idx + @lastSearch().length)}</b>#{text.substring(idx + @lastSearch().length)}"
        else
          text
      else
        text
