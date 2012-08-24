onChannels ->
  class @MainViewModel
    constructor: (@collectionId)->
      @channels = ko.observableArray()

