#= require module
#= require collections/locatable
#= require collections/sites_container
#= require collections/layer
#= require collections/field
onCollections ->

  class @CollectionBase extends Module
    @include Locatable
    @include SitesContainer

    constructor: (data) ->
      @constructorLocatable(data)
      @constructorSitesContainer()

      @id = data?.id
      @name = data?.name
      @currentSnapshot = if data?.snapshot_name then data?.snapshot_name else ''
      @updatedAt = ko.observable(data.updated_at)
      @updatedAtTimeago = ko.computed => if @updatedAt() then $.timeago(@updatedAt()) else ''
      @loadCurrentSnapshotMessage()
      @allSites = ko.observable()


    loadCurrentSnapshotMessage: =>
      @viewingCurrentSnapshotMessage = ko.observable()
      @viewingCurrentSnapshotMessage("You are currently viewing this collection's data as it was on snapshot " + @currentSnapshot + ".")

    fetchFields: (callback) =>
      if @fieldsInitialized
        callback() if callback && typeof(callback) == 'function'
        return

      @fieldsInitialized = true
      $.get "/collections/#{@id}/fields", {}, (data) =>
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

    link: (format) => "/api/collections/#{@id}.#{format}"

    level: => -1

    setQueryParams: (q) -> q

    performHierarchyChanges: (site, changes) =>

    sitesWithoutLocation: ->
      res = (site for site in this.sites() when !site.hasLocation())
      res

    unloadCurrentSnapshot: ->
      $.post "/collections/#{@id}/unload_current_snapshot.json", ->
        window.location.reload()
