describe 'MainViewModel', ->
  beforeEach ->
    window.runOnCallbacks 'channels'
    @collectionId =1
    @model = new MainViewModel @collectionId
    window.model = @model

  describe 'delete threshold', ->
    beforeEach ->
      @channel = new Channel {id:1, collection_id: @collectionId, name:'Regional (GSM)', is_enable: true, nuntium_channel_name: 'ch_01', is_manual_configuration: true, is_share: false, collections: [{id: 1, name: 'col 1'}, {id: 2, name: 'col 02'}]}
      @model.channels.push @channel
    
    it 'should show confirm dialog', ->
      spyOn window, 'confirm'
      @model.deleteChannel @channel
      expect(window.confirm).toHaveBeenCalledWith 'Are you sure to delete channel?'

    it 'should delete the channel', ->
      spyOn(window, 'confirm').andReturn true
      spyOn($, 'post').andReturn true
      @model.deleteChannel @channel
      @expect($.post).toHaveBeenCalledWith "/plugin/channels/collections/#{@collectionId}/channels/#{@channel.id}.json", { _method: 'delete' }, @model.deleteChannelCallback
