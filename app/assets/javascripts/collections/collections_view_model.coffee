onCollections ->

  class @CollectionsViewModel
    @constructorCollectionsViewModel: (collections) ->
      @collections = ko.observableArray $.map(collections, (x) -> new Collection(x))
      @currentCollection = ko.observable()
      @fullscreen = ko.observable(false)
      @currentSnapshot = ko.computed =>
        @currentCollection()?.currentSnapshot

    @findCollectionById: (id) -> (x for x in @collections() when x.id == id)[0]

    @goToRoot: -> location.hash = '/'

    @enterCollection: (collection) -> location.hash = "#{collection.id}"

    @editCollection: (collection) -> window.location = "/collections/#{collection.id}"

    @tooglefullscreen: ->
      if !@fullscreen()
        @fullscreen(true)
        $("body").addClass("fullscreen")
        $(".ffullscreen").addClass("frestore")
        $(".ffullscreen").removeClass("ffullscreen")
        window.adjustContainerSize()
      else
        @fullscreen(false)
        $("body").removeClass("fullscreen")
        $(".frestore").addClass("ffullscreen")
        $(".frestore").removeClass("frestore")
        window.adjustContainerSize()

    @createCollection: -> window.location = "/collections/new"
