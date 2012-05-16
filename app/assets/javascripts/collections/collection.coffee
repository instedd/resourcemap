#= require collections/collection_base

onCollections ->

  class @Collection extends CollectionBase
    constructor: (data) ->
      super(data)
      @layers = ko.observableArray()
      @fields = ko.observableArray()
      @checked = ko.observable true
      @fieldsInitialized = false

      @groupByOptions = ko.computed => [window.model.defaultGroupBy].concat(@fields().filter((f) -> f.kind() == 'hierarchy'))

    isSearch: => false

    sitesUrl: -> "/collections/#{@id()}/sites.json"

    fetchLocation: => $.get "/collections/#{@id()}.json", {}, (data) =>
      @position(data)
      @updatedAt(data.updated_at)
