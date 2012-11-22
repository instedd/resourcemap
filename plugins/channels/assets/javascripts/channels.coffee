#= require channels/on_channels
#= require_tree

onChannels -> if $('#channels-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/channels/)
  collectionId = parseInt(match[1])
  
  window.model = new MainViewModel(collectionId)
  ko.applyBindings(window.model)
  
  $.get "/plugin/channels/collections/#{collectionId}/channels.json", (data) ->
    window.model.channels $.map data, (channel) ->
      new Channel channel, collectionId

  
  $('.hidden-until-loaded').show()
