#= require site_memberships/on_site_memberships
#= require_tree

# We do the check again so tests don't trigger this initialization
onSiteMemberships -> if $('#site-memberships-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/site_memberships/)
  collectionId = parseInt(match[1])

  window.model = new MainViewModel(collectionId)
  ko.applyBindings(window.model)

  $.get "/collections/#{collectionId}/fields.json", (layers) ->
    fields = $.map(layers, (layer) -> layer.fields).filter (field) -> field.kind is 'user'

    $.get "/plugin/site_memberships/collections/#{collectionId}/site_memberships.json", (siteMemberships) ->
      memberships = $.map fields, (field) ->
        new Membership(field, siteMemberships.filter((m) -> m.field_id.toString() == field.id)[0] ? collection_id: collectionId)
      
      window.model.memberships memberships
      $('.hidden-until-loaded').show()
