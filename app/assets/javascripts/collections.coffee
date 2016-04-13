#= require collections/on_collections
#= require_tree ./collections/.

# We do the check again so tests don't trigger this initialization
onCollections -> if $('#collections-main').length > 0

  History.Adapter.bind window, 'statechange', (e) ->
    State = History.getState()

  # Start the view model for given collections
  initViewModel = (collections) =>
    window.model = new MainViewModel(collections)
    window.model.processURL()
    ko.applyBindings window.model
    window.model.isGatewayExist()
    $('#collections-dummy').remove()
    $('#collections-main').show()
    $('#refine-container').show()
    $('#snapshot_loaded_message').show()

  # If current_user is guest, she will only have access to the requested collection
  collectionId = parseInt($.url().param('collection_id'))
  if window.currentUserIsGuest
    Resmap.Api.Collections.get(collectionId).then (collection) ->
      initViewModel [collection]
  else
    Resmap.Api.Collections.all().then (collections) ->
      if !collectionId || _.any(collections, (c) -> c.id == collectionId)
        initViewModel(collections)
      else
        Resmap.Api.Collections.get(collectionId).then (collection) ->
          collections.push(collection)
          initViewModel(collections)

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
