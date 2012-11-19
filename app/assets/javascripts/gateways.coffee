#= require gateways/on_gateways
#= require_tree ./gateways/.

onGateways -> if $('#gateways-main').length > 0
  window.model = new MainViewModel
  ko.applyBindings(window.model)
  
  # $.get "/plugin/channels/collections/#{collectionId}/channels.json", (data) ->
  #   window.model.channels $.map data, (channel) ->
  #     #reminder.repeat = window.model.findRepeat repeatId if repeatId = reminder.repeat_id
  #     new Channel channel, collectionId

  
  $('.hidden-until-loaded').show()
