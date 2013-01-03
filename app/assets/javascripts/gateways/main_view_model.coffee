onGateways ->
  class @MainViewModel
    constructor: ()->
      @gateways         = ko.observableArray()
      @nationalGateways = ko.observableArray([])
      @currentGateway   = ko.observable()
      @originalGateway  = ko.observable()
      @isSaving         = ko.observable false
    
    addGateway: =>
      gateway = new Gateway  queued_messages_count: 0, name:'default-gateway', is_enable: true
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
        @gateways.remove @currentGateway()
      @currentGateway null
      delete @originalGateway

    getNuntiumInfoCallback: (data) =>
      console.log data

    showConfiguration: (gateway) =>
      gateway.viewConfiguration true

    hideConfiguration: (gateway) =>
      gateway.viewConfiguration false

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

    onOffEnable: (gateway) =>
      gateway.setStatus true, @channelStatusCallback

    onOffDisable: (gateway) =>
      gateway.setStatus false, @channelStatusCallback

    reminderStatusCallback: (data) =>

    setIsTry: (gateway) =>
      gateway.isTry true 

    tryGateway: (gateway) =>
      $.post "/gateways/#{gateway.id}/try.json", phone_number: gateway.tryPhoneNumber(), @tryGatewayCallback

    tryGatewayCallback: (data) =>
      gateway = @findGateway(data.id)
      gateway.isTry false
   
    cancel: (gateway)=>
      gateway.isTry false

    findGateway: (id) =>
      return gateway for gateway in @gateways() when gateway.id == id
