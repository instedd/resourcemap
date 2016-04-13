#= require layers/on_layers
#= require_tree ./layers/.

# We do the check again so tests don't trigger this initialization
onLayers -> if $('#layers-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/layers/)
  collectionId = parseInt(match[1])

  $('.hierarchy_upload').live 'change', ->
    $('.hierarchy_form').submit()
    window.model.startUploadHierarchy()

  Resmap.Api.Collections.getLayers(collectionId).then (layers) =>
    window.model = new MainViewModel(collectionId, layers)
    ko.applyBindings window.model

    $('.hidden-until-loaded').show()

    $(".fancybox").fancybox({
      afterClose: ->
        window.model.currentHierarchyUnderEdition(null)
    })

  $ ->
    $(".n-label").hover ->
      active = $(this).closest("li.active")
      if active.length > 0
        active.removeClass "active"
      else
        $(".h-editor li").removeClass "active"
        $(this).closest("li").toggleClass "active"

    false
