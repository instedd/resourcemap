$(-> if $('#collections-main').length > 0

  class window.CollectionDecorator extends CollectionBase
    constructor: (collection) ->
      @collection = collection

      @id = ko.observable collection.id()
      @name = ko.observable collection.name()
      @layers = collection.layers
      @fields = collection.fields
      @fieldsInitialized = collection.fieldsInitialized
      @groupByOptions = collection.groupByOptions

      @initSites()

      @constructorLocation(lat: collection.lat(), lng: collection.lng())

    createSite: (site) => new Site(@collection, site)

    # These two methods are needed to be forwarded when editing sites inside a search
    updatedAt: (value) => @collection.updatedAt(value)
    fetchLocation: => @collection.fetchLocation()

)
