onCollections ->

  class @SearchViewModel
    @constructor: ->
      @search = ko.observable('')
      @lastSearch = ko.observable(null)

      @inSearch = ko.computed => @currentCollection()?.isSearch()
      @div = ko.observable('')

    @performSearchOrHierarchy: ->
      return false if !@currentCollection() || @ignorePerformSearchOrHierarchy

      rootCollection = @currentCollection().collection ? @currentCollection()

      @unselectSite()

      if $.trim(@search()).length == 0 && @filters().length == 0 && !@sort()
        if @groupBy().esCode == ''
          @currentCollection(rootCollection)
        else
          @currentCollection(new CollectionHierarchy(rootCollection, @groupBy()))
        @lastSearch(null)
      else
        @currentCollection(new CollectionSearch(rootCollection, @search(), @filters(), @sort(), @sortDirection()))
        @lastSearch(@search())

      @currentCollection().loadMoreSites() if @currentCollection().sitesPage == 1

      if @showingMap()
        @reloadMapSites()
      else
        window.adjustContainerSize()

      @rewriteUrl()

      false

    @clearSearch: ->
      @search('')
      @performSearchOrHierarchy()

    @highlightSearch: (text) ->
      if !@div()
        @div($('<div/>'))

      text = @div().text(text).html()
      if @lastSearch()
        text = "#{text}"
        idx = text.toLowerCase().indexOf(@lastSearch().toLowerCase())
        if idx >= 0
          "#{text.substring(0, idx)}<b class=\"highlight\">#{text.substring(idx, idx + @lastSearch().length)}</b>#{text.substring(idx + @lastSearch().length)}"
        else
          text
      else
        text
