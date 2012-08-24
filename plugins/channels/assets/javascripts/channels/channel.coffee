onChannels ->
  class @Channel
    constructor: (data) ->
      @id           = data?.id
      @collectionId = data?.collection_id
      @name         = ko.observable data?.name
      @isEnable     = ko.observable data?.is_enable
      @nuntiumChannelName = ko.observable data?.nuntium_channel_name
      @isManualConfiguration = ko.observable data?.is_manual_configuration
      @isShare      = ko.observable data?.is_share
      @shareCollections = ko.observableArray data?.share_collections

