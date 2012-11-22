#= require collections/on_collections
#= require_tree ./collections/.

# We do the check again so tests don't trigger this initialization
onCollections -> if $('#collections-main').length > 0

  History.Adapter.bind window, 'statechange', (e) ->
      State = History.getState()

  # Get collections and start the view model
  $.get "/collections.json", {}, (collections) =>
    window.model = new MainViewModel
    window.model.initialize(collections)
    ko.applyBindings window.model
    console.log window.model
    window.model.processURL()
    window.model.isGatewayExist()
    $('#collections-dummy').remove()
    $('#collections-main').show()
    $('#refine-container').show()
    $('#snapshot_loaded_message').show()
  # Adjust width to window
  window.adjustContainerSize = ->
    width = $(window).width()
    containerWidth = width - 80
    containerWidth = 960 if containerWidth < 960

    $('#container').width(containerWidth)
    $('#header').width(containerWidth)
    $('.BreadCrumb').width(containerWidth - 410)
    $('#right-panel').width(containerWidth - 404)
    $('.tableheader.expanded').width(containerWidth)
    $('#map').width(containerWidth - 420)
    $('.h50').height(500)
    $('#map').height('')

    if(window.model && window.model.fullscreen())
      $('#container').width(width)
      $('.tableheader.expanded').width("100%")
      $('#right-panel').width(width - 404)
      $('#map').width("100%")
      $('#collections-main').height("100%")
      $('#collections-main .h50').height("100%")
      $('#map').height($('#collections-main').height() - $('.mapheader').height())
      $('.expand-collapse_button').css("top", (($('#map').height())/2 ) + "px");
      if(window.model.fullscreenExpanded())
        $('#right-panel').width(width)

    google.maps.event.trigger(map, "resize") if window.model && window.model.showingMap()
    false


  $(window).resize adjustContainerSize
  setTimeout(adjustContainerSize, 100)

  # Hide the refine popup if clicking outside it
  $(window.document).click (event) ->
    return if $('#ui-datepicker-div:visible').length > 0
    return if $('.ui-autocomplete').length > 0

    $refine = $('.refine')
    $refinePopup = $('.refine-popup')
    unless $refine.get(0) == event.target ||
           $refinePopup.get(0) == event.target ||
           $refine.has(event.target).length > 0 ||
           $refinePopup.has(event.target).length > 0
      window.model.toggleRefinePopup() if window.model.showingRefinePopup()
