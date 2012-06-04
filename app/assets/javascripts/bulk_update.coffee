#= require bulk_update/on_bulk_update
#= require_tree ./bulk_update/.

# We do the check again so tests don't trigger this initialization
onBulkUpdate -> if $('#bulk-update-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/bulk_update/)
  collectionId = parseInt(match[1])

  $.get "/collections/#{collectionId}/bulk_update_sample.json", {}, (columns) =>
    window.model = new MainViewModel(collectionId, columns)
    ko.applyBindings window.model

    $('.hidden-until-loaded').show()
