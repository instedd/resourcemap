#= require collections/collection_base

onCollections ->

  class @CollectionDecorator extends CollectionBase
    constructor: (collection, @collectionsApi = Resmap.Api.Collections) ->
      # These three are because we are not calling super
      @constructorLocatable(lat: collection.lat(), lng: collection.lng())
      @constructorSitesContainer(@collectionsApi)
      @constructorCollectionMembership(@collectionsApi)
      @loadCurrentSnapshotMessage()

      @loadAllSites()

      @collection = collection
      @currentSnapshot = collection.currentSnapshot

      @id = collection.id
      @name = collection.name
      @layers = collection.layers
      @fields = collection.fields
      @fieldsInitialized = collection.fieldsInitialized
      @refineFields = collection.fields
      @groupByOptions = collection.groupByOptions
      @sitesPermission = collection.sitesPermission
      @allSites(collection.allSites())
      @error = collection.error

      @namePermission = collection.namePermission
      @locationPermission = collection.locationPermission

    createSite: (site) => new Site(@collection, site)

    # These two methods are needed to be forwarded when editing sites inside a search
    updatedAt: (value) => @collection.updatedAt(value)
    fetchLocation: => @collection.fetchLocation()
