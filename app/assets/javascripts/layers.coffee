window.onLayers = (callback) -> $(-> callback() if $('#layers-main').length > 0)

onLayers ->
  match = window.location.toString().match(/\/collections\/(\d+)\/layers/)
  collectionId = parseInt(match[1])

  $('.hierarchy_upload').live 'change', ->
    $('.hierarchy_form').submit()
    window.model.startUploadHierarchy()

  $.get "/collections/#{collectionId}/layers.json", {}, (layers) =>
    window.model = new LayersViewModel(collectionId, layers)
    ko.applyBindings window.model

    $('.hidden-until-loaded').show()
