#= require site_memberships/on_site_memberships
#= require_tree

# We do the check again so tests don't trigger this initialization
onSiteMemberships -> if $('#site-memberships-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/site_memberships/)
  collectionId = parseInt(match[1])
  
  window.model = new MainViewModel(collectionId)
  ko.applyBindings(window.model)
  
  $('.hidden-until-loaded').show()