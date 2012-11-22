#= require gateways/on_gateways
#= require_tree ./gateways/.

onGateways -> if $('#gateways-main').length > 0
  window.model = new MainViewModel
  ko.applyBindings(window.model)
  
  $.get "/gateways.json", (data) ->
    window.model.gateways $.map data, (gateway) ->
      new Gateway gateway

  
  $('.hidden-until-loaded').show()
