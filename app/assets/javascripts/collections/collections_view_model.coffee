onCollections ->

  class @CollectionsViewModel
    @constructorCollectionsViewModel: (collections) ->
      @collections = ko.observableArray $.map(collections, (x) -> new Collection(x))
      @currentCollection = ko.observable()
      @currentSnapshot = ko.computed =>
        @currentCollection()?.currentSnapshot

    @findCollectionById: (id) -> (x for x in @collections() when x.id == id)[0]

    @goToRoot: -> location.hash = '/'

    @enterCollection: (collection) -> location.hash = "#{collection.id}"

    @editCollection: (collection) -> window.location = "/collections/#{collection.id}"

    @createCollection: -> window.location = "/collections/new"
