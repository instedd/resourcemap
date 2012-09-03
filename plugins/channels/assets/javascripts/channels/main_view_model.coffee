onChannels ->
  class @MainViewModel
    constructor: (@collectionId)->
      @channels         = ko.observableArray()
      @sharedChannels   = ko.observableArray()
      @currentChannel   = ko.observable()
      @originalChannel  = ko.observable()
      @collections      = ko.observableArray([])
      @collectionId     = ko.observable collectionId 
      @isSaving         = ko.observable false
    
    showAddChannel: =>
      channel = new Channel collection_id: @collectionId(), is_share: 'false', is_manual_configuration: false
      @currentChannel channel
      @channels.push channel

    saveChannel: =>
      @isSaving true
      json = @currentChannel().toJson()
      if @currentChannel().id
        $.post "/plugin/channels/collections/#{@collectionId()}/channels/#{@currentChannel().id}.json", channel: json, _method: 'put', @saveChannelCallback
      else
        $.post "/plugin/channels/collections/#{@collectionId()}/channels.json", channel: json, @saveChannelCallback

    saveChannelCallback: (data) =>
      @currentChannel().id = data.id
      @currentChannel null
      @isSaving false

    cancelChannel: =>
      $.get "/plugin/channels/collections/#{@collectionId()}/channels/#{@currentChannel().id}.json", nuntium_info: true, @getNuntiumInfoCallback

    getNuntiumInfoCallback: (data) =>
      console.log data

    editChannel: (channel) =>
      @originalChannel = channel.clone()
      @currentChannel channel
      console.log @currentChannel()

    deleteChannel: (channel) =>
      if window.confirm 'Are you sure to delete channel?'
        @deletedChannel = channel
        $.post "/plugin/channels/collections/#{@collectionId()}/channels/#{channel.id}.json", { _method: 'delete' }, @deleteChannelCallback 

    deleteChannelCallback: =>
      @channels.remove @deletedChannel
      delete @deletedChannel
