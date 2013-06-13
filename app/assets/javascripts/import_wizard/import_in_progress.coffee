#= require import_wizard/on_import_wizard
#= require_tree .

# We do the check again so tests don't trigger this initialization
onImportInProgress -> if $('#import-in-progress').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/import_wizard/)
  collectionId = parseInt(match[1])

  poll_status = ->
    $.get "/collections/#{collectionId}/import_wizard/job_status.json", {}, (data) =>
      status = data.status
      if status == 'finished' || status == 'failed'
        window.location = "/collections/#{collectionId}/import_wizard/import_#{status}"
      else if status == 'in_progress'
        $(".pending_jobs").hide()
        $(".in_progress").show()

      setTimeout(poll_status, 2000)

  poll_status()
