#= require channels/on_channels
#= require_tree

onChannels -> if $('#channels-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/channels/)
  collectionId = parseInt(match[1])
  
  window.model = new MainViewModel(collectionId)
  
  ko.applyBindings(window.model)
  
  $.get "/gateways.json", without_nuntium: true, (data) ->
      window.model.gateways $.map data, (channel) ->
        new Option channel
  
  $.get "/plugin/channels/collections/#{collectionId}/channels.json", (data) ->
    window.model.selectedGateways $.map data, (channel) ->
      channel.id.toString()
  
  $('.hidden-until-loaded').show()
