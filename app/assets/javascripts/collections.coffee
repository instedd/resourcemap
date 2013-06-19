#= require collections/on_collections
#= require_tree ./collections/.

# We do the check again so tests don't trigger this initialization
onCollections -> if $('#collections-main').length > 0

  History.Adapter.bind window, 'statechange', (e) ->
      State = History.getState()

  # Start the view model for given collections
  initViewModel = (collections) =>
    window.model = new MainViewModel(collections)
    ko.applyBindings window.model
    window.model.processURL()
    window.model.isGatewayExist()
    $('#collections-dummy').remove()
    $('#collections-main').show()
    $('#refine-container').show()
    $('#snapshot_loaded_message').show()

  # If current_user is guest, she will only have access to the requested collection
  if window.currentUserIsGuest
    collectionId = $.url().param('collection_id')
    $.get "/collections/#{collectionId}.json", {}, (collection) ->
      initViewModel [collection]
  else
    $.get "/collections.json", {}, initViewModel

  # Adjust width to window
  window.adjustContainerSize = ->
    adjustRightPanelWidth = (referenceWidth) =>
      $('#right-panel').width(referenceWidth - 304)

    $('.left .tablescroll').height(420)
    $('.slightly-padded .tablescroll').height(420)

    width = $(window).width()
    containerWidth = width - 80
    containerWidth = 960 if containerWidth < 960

    $('#container').width(containerWidth)
    $('#header').width(containerWidth)
    $('.BreadCrumb').width(containerWidth - 410)

    adjustRightPanelWidth(containerWidth)

    $('.tableheader.expanded').width(containerWidth)
    $('#map').width(containerWidth - 320)
    $('.h50').height(500)
    $('#map').height('')

    if(window.model && window.model.fullscreen())
      container = $('#container')
      left_body = $('.fullscreen .tablescroll')
      table_header = $('.tableheader.expanded')
      table_bottom = $('.tablebottom')
      map = $('#map')
      collections_main = $('#collections-main')
      collections_main_inner = $('#collections-main .h50')
      expand_collapse_button = $('.expand-collapse_button')
      right_panel = $('#right-panel')
      refine_container = $('#refine-container')
      table_body_on_table_mode = $('.fht-body')

      container.width(width)

      table_header.width("100%")

      adjustRightPanelWidth(width)

      height_for_body = container.height() - table_header.height() - table_bottom.height() - 48

      height_for_map = height_for_body + 9

      if window.model.currentCollection()
        height_for_body = height_for_body - refine_container.height()
        height_for_map = height_for_map - refine_container.height()

      if window.model.showingMap()
        left_body.height(height_for_body)
      else
        left_body.height(height_for_body + 35)
        $('table.GralTable').fixedHeaderTable({ height: height_for_body})

      map.width("100%")
      collections_main.height("100%")
      collections_main_inner.height("100%")
      map.height(height_for_map)
      expand_collapse_button.css("top", ((map.height())/2 ) + "px");

      if(window.model.fullscreenExpanded())
        right_panel.width(width)

    google.maps.event.trigger(map, "resize") if window.model && window.model.showingMap() && map
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
