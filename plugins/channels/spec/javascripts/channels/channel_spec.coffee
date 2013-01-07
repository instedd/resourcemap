describe 'Channel', ->
  xit -> 
    beforeEach ->
      window.runOnCallbacks 'channels'
      @collectionId = 1
      @channel = new Channel {id:1, collection_id: @collectionId, name:'Regional (GSM)', ticket_code: '', password: '12345', is_manual_configuration: true, is_share: 'false', share_collections: []}, @collectionId
    it 'should have 1 channel', ->
      expect(@channel.valid()).toBeTruthy()

    it 'should have property is_admin = true', ->
      expect(@channel.isAdmin).toBeTruthy()

    it 'should not valid when password less than 4 characters', ->
      @channel.password '12'
      expect(@channel.valid()).toBeFalsy()

    it 'should not valid when name less than 4 characters', ->
      @channel.name 'ab'
      expect(@channel.valid()).toBeFalsy()

    it 'should parsed to Json format', ->
      expect(@channel.toJson()).toEqual {
        id: 1
        collection_id           : @collectionId
        name                    : 'Regional (GSM)'
        is_share                : 'false'
        is_manual_configuration : true
        password                : '12345'
        ticket_code             : ''
        share_collections       : []
      }
