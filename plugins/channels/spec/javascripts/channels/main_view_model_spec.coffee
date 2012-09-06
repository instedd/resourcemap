describe 'MainViewModel', ->
  beforeEach ->
    window.runOnCallbacks 'channels'
    @collectionId =1
    @model = new MainViewModel @collectionId
    window.model = @model

  describe 'create threshold', ->
    beforeEach ->
      @model.addChannel()

    it 'should add channel to channels', ->
      expect(@model.channels().length).toEqual 1

    it 'should add channel to channels with property isAdmin = true', ->
      expect(@model.channels()[0].isAdmin).toEqual true
    
    it 'should add channel to channels with property queued_messages_count = 0', ->
      expect(@model.channels()[0].queuedMessageText()).toMatch(/Client disconected,0 message pending/)

    it 'should add channel to channels with is_manual_configuration = true', ->
      expect(@model.channels()[0].isManualConfiguration()).toBeTruthy

    it 'should add channel to channels with is_share = true', ->
      expect(@model.channels()[0].isShare()).toMatch(/false/)
    
  describe 'edit channel', ->
    beforeEach ->
      @channel = new Channel {id:1, collection_id: @collectionId, name:'Regional (GSM)', password: '12345', is_enable: true, nuntium_channel_name: 'ch_01', is_manual_configuration: true, is_share: false, collections: [{id: 3, name: 'col 1'}, {id: 2, name: 'col 02'}]}
      @model.channels.push @channel
      @model.editChannel @channel
    
    it 'should restore channel name after cancel', ->
      @model.channels()[0].name()
      @model.cancelChannel()
      expect(@model.channels()[0].name()).toEqual('Regional (GSM)')
 
    it "should restore channel's password after cancel", ->
      @model.channels()[0].password(9999)
      @model.cancelChannel()
      expect(@model.channels()[0].password()).toMatch(/12345/)

    it "should restore channel's shared_collections after cancel", ->
      @model.channels()[0].sharedCollections()
      @model.cancelChannel()
      expect(@model.channels()[0].sharedCollections()).toEqual [{id: 3, name: 'col 1'}, {id: 2, name: 'col 02'}]

  describe 'delete channel', ->
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
