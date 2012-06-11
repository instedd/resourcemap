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
      @updatedAt = ko.observable(data.updated_at)
      @updatedAtTimeago = ko.computed => if @updatedAt() then $.timeago(@updatedAt()) else ''

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
