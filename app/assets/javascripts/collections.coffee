#= require collections/on_collections
#= require_tree ./collections/.

# We do the check again so tests don't trigger this initialization
onCollections -> if $('#collections-main').length > 0

  History.Adapter.bind window, 'statechange', (e) ->
      State = History.getState()
      History.log(State.data, State.title, State.url)

  # Get collections and start the view model
  $.get "/collections.json", {}, (collections) =>
    window.model = new MainViewModel
    window.model.initialize(collections)
    ko.applyBindings window.model

    window.model.goToRoot()

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
    $('#map').height('')
    $('.mapcontainer').height('')
    $('.h50').height(500)
    $('#collections-main .left').addClass("w40")
    $('#collections-main').css('overflow', "")
    $('#collections-main .left').width("")

    if(window.model && window.model.fullscreen())
      $('#container').width('100%')
      $('.tableheader.expanded').width("100%")
      $('#right-panel').width(width - 404)
      $('#map').width("100%")
      $('#map').height('95%%')
      $('.mapcontainer').height('95%%')
      $('#collections-main').height("95%")
      $('#collections-main .h50').height("100%")
      $('#collections-main .left').removeClass("w40")
      $('#collections-main .left').width("30%")
      $('#right-panel').width("70%")
      $('#collections-main').css('overflow', "hidden")
      $('.expand-collapse_button').css("top", (($('#map').height())/2 ) + "px");
      if(window.model.fullscreenExpanded())
        $('#right-panel').width(width)

    google.maps.event.trigger(map, "resize") if window.model && window.model.showingMap()
    false


  $(window).resize adjustContainerSize
  setTimeout(adjustContainerSize, 100)

  # Hide the refine popup if clicking outside it
  $(window.document).click (event) ->
    $refine = $('.refine')
    $refinePopup = $('.refine-popup')
    unless $refine.get(0) == event.target ||
           $refinePopup.get(0) == event.target ||
           $refine.has(event.target).length > 0 ||
           $refinePopup.has(event.target).length > 0
      window.model.toggleRefinePopup() if window.model.showingRefinePopup()
