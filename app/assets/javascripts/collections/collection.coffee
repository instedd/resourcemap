#= require collections/collection_base

onCollections ->

  class @Collection extends CollectionBase
    constructor: (data, @collectionsApi = Resmap.Api.Collections) ->
      super(data)
      @minLat = data?.min_lat
      @maxLat = data?.max_lat
      @minLng = data?.min_lng
      @maxLng = data?.max_lng
      @fields = ko.observableArray()

      # The error in the name field of the current site
      @nameFieldError = ko.observable()

      @error = ko.computed =>
        @nameFieldError() || window.arrayAny(@fields(), (f) => f.error())

      @refineFields = ko.observableArray()
      @checked = ko.observable true
      @fieldsInitialized = false

      @groupByOptions = ko.computed =>
        defaultOptions = []
        if window.model
          defaultOptions =[window.model.defaultGroupBy]
        defaultOptions.concat(@fields().filter((f) -> f.showInGroupBy))



    isSearch: => false

    fetchSites: (options) ->
      @collectionsApi.fetchSites(@id, options)

    fetchLocation: ->
      @collectionsApi.get(@id).then (data) =>
        @minLat = data.min_lat
        @maxLat = data.max_lat
        @minLng = data.min_lng
        @maxLng = data.max_lng
        @position(data)   # update the position in Locatable
        @updatedAt(data.updated_at)

    panToPosition: =>
      if @minLat && @maxLat && @minLng && @maxLng
        window.model.map.fitBounds new google.maps.LatLngBounds(
          new google.maps.LatLng(@minLat, @minLng),
          new google.maps.LatLng(@maxLat, @maxLng)
        )
      else if @position()
        window.model.map.panTo @position()
