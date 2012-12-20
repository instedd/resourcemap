#= require gateways/on_gateways
#= require_tree ./gateways/.

onGateways -> if $('#gateways-main').length > 0
  window.model = new MainViewModel
  ko.applyBindings(window.model)
  
  $.get "/gateways.json", (data) ->
    window.model.gateways $.map data, (gateway) ->
      new Gateway gateway

    window.model.nationalGateways [{name: 'International Gateway(clickatell)', code: 'clickatell44911'}, {name: 'Lao National Gateway(etl)', code: 'etl'},{name: 'Cambodia National Gateway(smart)', code: 'smart'}, {name: "Cambodia National Gateway(mobitel)", code: 'camgsm'}]
  $('.hidden-until-loaded').show()
