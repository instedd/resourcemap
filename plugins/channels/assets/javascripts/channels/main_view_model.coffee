onChannels ->
  class @MainViewModel
    constructor: (@collectionId)->
      @gateways         = ko.observableArray()
      @selectedGateways = ko.observableArray()
      @collectionId     = ko.observable collectionId 
    
    saveChannel: =>
      $.post "/collections/#{@collectionId()}/register_gateways.json", gateways: @selectedGateways(), @saveChannelCallback

    saveChannelCallback: (data) =>
      console.log data
