onCollections ->

  class @CustomLogoViewModel
    @constructor: (collections, @api = Resmap.Api) ->
      @collection_has_logo = ko.computed =>
        if @currentCollection()
          if @currentCollection().logoUrl == undefined
            @currentCollection().fetchLogoUrl()
          @currentCollection().logoUrl != undefined && @currentCollection().logoUrl != null

      @image_src = ko.computed =>
        if @collection_has_logo()
          @currentCollection().logoUrl
        else
          ""
