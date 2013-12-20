#= require collections/collection_base

onCollections ->

  class @Collection extends CollectionBase
    constructor: (data) ->
      super(data)
      @minLat = data?.min_lat
      @maxLat = data?.max_lat
      @minLng = data?.min_lng
      @maxLng = data?.max_lng
      @layers = ko.observableArray()
      @fields = ko.observableArray()
      @logoUrl = data?.logo_url

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

    sitesUrl: -> "/collections/#{@id}/sites.json"

    fetchLocation: => $.get "/collections/#{@id}.json", {}, (data) =>
      @minLat = data.min_lat
      @maxLat = data.max_lat
      @minLng = data.min_lng
      @maxLng = data.max_lng
      @position(data)
      @updatedAt(data.updated_at)

    fetchLogoUrl: => $.get "/collections/#{@id}.json", {}, (data) =>
      @logoUrl = data.logo.grayscale.url

    panToPosition: =>
      if @minLat && @maxLat && @minLng && @maxLng
        window.model.map.fitBounds new google.maps.LatLngBounds(
          new google.maps.LatLng(@minLat, @minLng),
          new google.maps.LatLng(@maxLat, @maxLng)
        )
      else if @position()
        window.model.map.panTo @position()
