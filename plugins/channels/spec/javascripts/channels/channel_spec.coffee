describe 'Channel', ->
  beforeEach ->
    window.runOnCallbacks 'channels'
    @collectionId = 1
    @channel = new Channel {id:1, collection_id: @collectionId, name:'Regional (GSM)', is_enable: true, nuntium_channel_name: 'ch_01', is_manual_configuration: true, is_share: false, collections: [{id: 1, name: 'col 1'}, {id: 2, name: 'col 02'}]}

  it 'should have 1 channel', ->
    #expect(@channel.valid()).toBeTruthy()
    #
  it 'should parsed to Json format', ->
    expect(@channel.toJson()).toEqual {
      id: 1
      collection_id: @collectionId
      name: 'Regional (GSM)'
      is_share: 'false'
      is_manual_configuration: true
      nuntium_channel_name: 'ch_01'
      share_collections : [2]
    }


