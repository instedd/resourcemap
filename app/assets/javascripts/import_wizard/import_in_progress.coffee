#= require import_wizard/on_import_wizard
#= require_tree .

# We do the check again so tests don't trigger this initialization
onImportInProgress -> if $('#import-in-progress').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/import_wizard/)
  collectionId = parseInt(match[1])

  poll_status = ->
    $.get "/collections/#{collectionId}/import_wizard/job_status.json", {}, (data) =>
      if (data == 'finished')
        window.location = "/collections/#{collectionId}/import_wizard/import_finished"
      else
        setTimeout(poll_status, 2000)

  poll_status()



