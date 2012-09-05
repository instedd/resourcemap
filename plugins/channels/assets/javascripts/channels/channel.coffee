onChannels ->
  class @Channel
    constructor: (data) ->
      @id                     = data?.id
      @collectionId           = data?.collection_id
      @name                   = ko.observable data?.name
      @password               = ko.observable data?.password
      @ticketCode             = ko.observable data?.ticket_code 
      @isEnable               = ko.observable data?.is_enable
      @nuntiumChannelName     = ko.observable data?.nuntium_channel_name
      @isManualConfiguration  = ko.observable data?.is_manual_configuration
      @isShare                = ko.observable data?.is_share.toString()
      @clientConnected        = ko.observable data?.client_connected
      
      @queuedMessageCount    = ko.observable 'Client disconected,' + data?.queued_messages_count + ' messages pending'
      @phoneNumber            = ko.observable data?.phone_number
      @gateWayURL             = ko.observable data?.gateway_url
      @sharedCollections      = ko.observable $.map data?.collections ? [], (collection) -> 
        new Collection(collection) if(collection.id != data.collection_id)
      @valid                  = ko.observable()
      @propertyError          = ko.computed =>
        return true
      @nameError              = ko.computed => "Channel's name is missing" if $.trim(@name()).length == 0
      @error                  = ko.computed => @nameError()
      
      @enableCss              = ko.observable 'cb-enable'
      @disableCss             = ko.observable 'cb-disalbe'
      @status                 = ko.observable data?.status
      @statusInit             = ko.computed =>
        if @status()
          @enableCss 'cb-enable selected'
          @disableCss 'cb-disable'
        else
          @enableCss 'cb-enable'
          @disableCss 'cb-disable selected'
      
    toJson: ->
      id                      : @id
      collection_id           : @collectionId
      name                    : @name()
      is_share                : @isShare()
      is_manual_configuration : @isManualConfiguration()
      nuntium_channel_name    : @nuntiumChannelName()
      share_collections       : $.map(@sharedCollections(), (collection) -> collection.id)
      password                : @password()
      ticket_code             : @ticketCode()

    clone: =>
      new Channel
        id                      : @id
        name                    : @name()
        is_share                : @isShare()
        is_manual_configuration : @isManualConfiguration()
        nuntium_channel_name    : @nuntiumChannelName()
        collections             : @sharedCollections()
        password                : @password()
        ticket_code             : @ticketCode()

    setStatus: (status, callback) ->
      @status status
      collectionId = parseInt(window.location.toString().match(/\/collections\/(\d+)\/channels/)[1])
      $.post "/plugin/channels/collections/#{collectionId}/channels/#{@id}/set_status.json", {status: status}, callback 
