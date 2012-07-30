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
      @checked = ko.observable true
      @fieldsInitialized = false

      @groupByOptions = ko.computed => [window.model.defaultGroupBy].concat(@fields().filter((f) -> f.showInGroupBy))

    isSearch: => false

    sitesUrl: -> "/collections/#{@id}/sites.json"

    fetchLocation: => $.get "/collections/#{@id}.json", {}, (data) =>
      @position(data)
      @updatedAt(data.updated_at)

    panToPosition: =>
      if @minLat && @maxLat && @minLng && @maxLng
        window.model.map.fitBounds new google.maps.LatLngBounds(
          new google.maps.LatLng(@minLat, @minLng),
          new google.maps.LatLng(@maxLat, @maxLng)
        )
      else if @position()
        window.model.map.panTo @position()

    searchUsersUrl: -> "/collections/#{@id}/memberships/search.json"

    unloadCurrentSnapshot: ->
      $.post "/collections/#{@id}/unload_current_snapshot.json", ->
        window.location.reload()

