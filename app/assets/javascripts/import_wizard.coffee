#= require import_wizard/on_import_wizard
#= require_tree ./import_wizard/.

# We do the check again so tests don't trigger this initialization
onImportWizard -> if $('#import-wizard-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/import_wizard/)
  collectionId = parseInt(match[1])

  $.get "/collections/#{collectionId}/fields.json", {}, (layers) =>
    $.get "/collections/#{collectionId}/import_wizard_sample.json", {}, (columns) =>
      window.model = new MainViewModel
      window.model.initialize collectionId, layers, columns

      ko.applyBindings window.model

      $('.hidden-until-loaded').show()
