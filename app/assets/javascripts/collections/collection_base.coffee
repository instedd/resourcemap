#= require module
#= require collections/locatable
#= require collections/sites_container
#= require collections/collection_membership
#= require collections/layer
#= require collections/field
onCollections ->

  class @CollectionBase extends Module
    @include Locatable
    @include SitesContainer
    @include CollectionMembership

    constructor: (data, @collectionsApi = Resmap.Api.Collections) ->
      @constructorLocatable(data)
      @constructorSitesContainer()
      @constructorCollectionMembership()

      @id = data?.id
      @name = data?.name
      @currentSnapshot = if data?.snapshot_name then data?.snapshot_name else ''
      @updatedAt = ko.observable(data.updated_at)
      @updatedAtTimeago = ko.computed => if @updatedAt() then $.timeago(@updatedAt()) else ''
      @logoUrl = data?.logo_url
      @loadCurrentSnapshotMessage()
      @loadAllSites()
      @layers = ko.observableArray()


    fieldsByLayers: () =>
      res = []
      for l in @layers()
        for f in l.fields
          res.push f

      res

    loadAllSites: =>
      @allSites = ko.observable()

    findSiteNameById: (value) =>
      allSites = window.model.currentCollection().allSites()
      return if not allSites
      (site.name for site in allSites when site.id is parseInt(value))[0]

    findSiteIdByName: (value) =>
      id = (site for site in window.model.currentCollection().allSites() when site.name is value)[0]?.id
      id

    loadCurrentSnapshotMessage: =>
      @viewingCurrentSnapshotMessage = ko.observable()
      @viewingCurrentSnapshotMessage("You are currently viewing this collection's data as it was on snapshot " + @currentSnapshot + ".")

    fetchFields: (callback) =>
      if @fieldsInitialized
        callback() if callback && typeof(callback) == 'function'
        return

      @fieldsInitialized = true
      @collectionsApi.getFields(@id).then (data) =>
        @layers($.map(data, (x) => new Layer(x)))

        fields = []
        for layer in @layers()
          for field in layer.fields
            fields.push(field)

        @fields(fields)
        @refineFields(fields)
        @refineFields.sort (f1, f2) ->
          lowerF1 = f1.name.toLowerCase()
          lowerF2 = f2.name.toLowerCase()
          if lowerF1 == lowerF2 then 0 else (if lowerF1 > lowerF2 then 1 else -1)
        callback() if callback && typeof(callback) == 'function'

    findFieldByEsCode: (esCode) => (field for field in @fields() when field.esCode == esCode)[0]

    clearFieldValues: =>
      field.value(null) for field in @fields()

    propagateUpdatedAt: (value) =>
      @updatedAt(value)

    exportUrl: (format) ->
      @collectionsApi.exportUrl(@id, format)

    level: => -1

    setQueryParams: (q) -> q

    performHierarchyChanges: (site, changes) =>

    sitesWithoutLocation: ->
      res = (site for site in this.sites() when !site.hasLocation())
      res

    unloadCurrentSnapshot: ->
      @collectionsApi.unloadCurrentSnapshot(@id).then ->
        window.location.reload()

    searchUsersUrl: ->
      @collectionsApi.searchUsersUrl(@id)

    searchSitesUrl: ->
      @collectionsApi.searchSitesUrl(@id)

    fetchLogoUrl: ->
      @collectionsApi.get(@id).then (data) =>
        @logoUrl = data.logo.grayscale.url
