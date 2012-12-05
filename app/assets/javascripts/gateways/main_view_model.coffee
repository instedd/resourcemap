onGateways ->
  class @MainViewModel
    constructor: ()->
      @gateways         = ko.observableArray()
      @currentGateway   = ko.observable()
      @originalGateway  = ko.observable()
      @isSaving         = ko.observable false
    
    addGateway: =>
      gateway = new Gateway is_share: 'false', is_manual_configuration: false, queued_messages_count: 0, name:'default-gateway'
      @currentGateway gateway 
      @gateways.push gateway

    saveGateway: =>
      @isSaving true
      json = @currentGateway().toJson()
      if @currentGateway().id
        $.post "/gateways/#{@currentGateway().id}.json", gateway: json, _method: 'put', @saveGatewayCallback
      else
        $.post "/gateways.json", gateway: json, @saveGatewayCallback

    saveGatewayCallback: (data) =>
      @currentGateway().id = data.id
      @currentGateway null
      @isSaving false

    cancelGateway: =>
      if @currentGateway().id
        @gateways.replace @currentGateway(), @originalGateway
      else
        @gateways.remove @currentGateway
      @currentGateway null
      delete @originalGateway

    getNuntiumInfoCallback: (data) =>
      console.log data

    editGateway: (gateway) =>
      @originalGateway = gateway.clone()
      @currentGateway gateway 

    deleteGateway: (gateway) =>
      if window.confirm 'Are you sure to delete this gateway?'
        @deletedGateway = gateway 
        $.post "gateways/#{gateway.id}.json", { _method: 'delete' }, @deleteGatewayCallback 

    deleteGatewayCallback: =>
      @gateways.remove @deletedGateway
      delete @deletedGateway

    onOffEnable: (channel) =>
      channel.setStatus true, @channelStatusCallback

    onOffDisable: (channel) =>
      channel.setStatus false, @channelStatusCallback

    reminderStatusCallback: (data) =>

    setIsTry: (gateway) =>
      gateway.isTry true 

    tryGateway: (gateway) =>
      $.post "/gateways/#{gateway.id}/try.json", phone_number: gateway.tryPhoneNumber(), @tryGatewayCallback

    tryGatewayCallback: (data) =>
      gateway = @findGateway(data.id)
      gateway.isTry false
    
    findGateway: (id) =>
      return gateway for gateway in @gateways() when gateway.id == id
