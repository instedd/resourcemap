onChannels ->
  class @Channel
    constructor: (data, currentCollectionId) ->
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
      @isAdmin                = data?.collection_id == currentCollectionId
      @queuedMessageCount     = ko.computed =>
        messageText = 'Client disconected,' + data?.queued_messages_count
        if data?.queued_messages_count > 1
          return messageText + ' messages pending'
        else
          return messageText + ' message pending'
      
      @phoneNumber            = ko.observable data?.phone_number
      @gateWayURL             = ko.observable data?.gateway_url
      @sharedCollections      = ko.observable $.map data?.collections ? [], (collection) -> 
        new Collection(collection) if(collection.id != data.collection_id)
      @nameError              = ko.computed => 
        length = $.trim(@name()).length
        if length < 1
          "Channel's name is missing"
        else if length < 4
          "Channel's name require at least 4 characters"
      @shareCollectionError   = ko.computed => 
        return null if @isShare() == "false" 
        "Share Channels is missing" if $.trim(@sharedCollections()).length == 0 
      @passwordError          = ko.computed => 
        return null if !@isManualConfiguration() 
        length = $.trim(@password()).length
        if length < 1
          "Channel's password is missing"
        else if length < 4
          "Channel's password require at least 4 characters"
      @ticketCodeError        = ko.computed =>
        return null if @isManualConfiguration()
        "Channel's ticket code is missing" if $.trim(@ticketCode()).length == 0
      @error                  = ko.computed => 
        return @nameError() if @nameError()
        return @passwordError() if @passwordError()
        return @ticketCodeError() if @ticketCodeError() 
        return @shareCollectionError() if @shareCollectionError() 
      
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
      
      @valid                  = ko.computed => not @error()?
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
