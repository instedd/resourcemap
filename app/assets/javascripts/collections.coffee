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
