#= require layers/on_layers
#= require_tree ./layers/.

# We do the check again so tests don't trigger this initialization
onLayers -> if $('#layers-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/layers/)
  collectionId = parseInt(match[1])

  $('.hierarchy_upload').live 'change', ->
    $('.hierarchy_form').submit()
    window.model.startUploadHierarchy()

  $.get "/collections/#{collectionId}/layers.json", {}, (layers) =>
    window.model = new MainViewModel(collectionId, layers)
    ko.applyBindings window.model

    $('.hidden-until-loaded').show()
