@Resmap ?= {}
@Resmap.Api ?= {}

Resmap.Api.Collections =
  all: ->
    $.get "/collections.json", {}
  get: (collectionId) ->
    $.get "/collections/#{collectionId}.json", {}
  getSitesInfo: (collectionId) ->
    $.get "/collections/#{collectionId}/sites_info.json", {}
  getMaxValueOfProperty: (collectionId, field) ->
    $.get "/collections/#{collectionId}/max_value_of_property.json", {property: field}
  fetchSites: (collectionId, options = {}) ->
    $.get "/collections/#{collectionId}/sites.json", options
  searchSites: (collectionId, searchParams, options = {}) ->
    $.get "/collections/#{collectionId}/search.json?#{$.param searchParams}", options
  getFields: (collectionId) ->
    $.get "/collections/#{collectionId}/fields", {}
  getLayers: (collectionId) ->
    $.get "/collections/#{collectionId}/layers.json", {}
  unloadCurrentSnapshot: (collectionId) ->
    $.post "/collections/#{collectionId}/unload_current_snapshot.json"
  exportUrl: (collectionId, format, extraParams) ->
    if extraParams
      "/api/collections/#{collectionId}.#{format}?#{$.param extraParams}"
    else
      "/api/collections/#{collectionId}.#{format}"
  searchUsersUrl: (collectionId) ->
    "/collections/#{collectionId}/memberships/search.json"
  searchSitesUrl: (collectionId) ->
    "/collections/#{collectionId}/sites_by_term.json"
  getSitesPermission: (collectionId) ->
    $.get "/collections/#{collectionId}/sites_permission", {}
  getCurrentUserMembership: (collectionId) ->
    $.get "/collections/#{collectionId}/current_user_membership.json", {}
  searchSitesByTerm: (collectionId, term = null) ->
    if term
      $.get "/collections/#{collectionId}/sites_by_term.json?term=#{term}"
    else
      $.get "/collections/#{collectionId}/sites_by_term.json"
  collectionUrl: (collectionId) ->
    "/collections/#{collectionId}"
  newCollectionUrl: ->
    "/collections/new"
  getSite: (collectionId, siteId) ->
    $.get "/collections/#{collectionId}/sites/#{siteId}.json", {}
  partialUpdateSite: (collectionId, siteId, data, options = {}) ->
    requestOptions = _.merge({
      type: "POST"
      url: "/collections/#{collectionId}/sites/#{siteId}/partial_update.json"
      data: data
    }, options)
    $.ajax requestOptions
  createSite: (collectionId, data, options = {}) ->
    requestOptions = _.merge({
      type: "POST"
      url: "/collections/#{collectionId}/sites"
      data: data
    }, options)
    $.ajax requestOptions
  deleteSite: (collectionId, siteId) ->
    $.post "/sites/#{siteId}", collection_id: collectionId, _method: 'delete'
  importLayersFromUrl: (collectionId, fromCollectionId) ->
    "/collections/#{collectionId}/import_layers_from/#{fromCollectionId}"
  saveLayer: (collectionId, layerId, data) ->
    $.post "/collections/#{collectionId}/layers/#{layerId}.json", _.merge({_method: 'put'}, data)
  createLayer: (collectionId, data) ->
    $.post "/collections/#{collectionId}/layers.json", data
  setLayerOrder: (collectionId, layerId, order) ->
    data = {_method: 'put', ord: order}
    $.post "/collections/#{collectionId}/layers/#{layerId}/set_order.json", data
  deleteLayer: (collectionId, layerId) ->
    $.post "/collections/#{collectionId}/layers/#{layerId}", {_method: 'delete'}

Resmap.Api.Sites =
  search: (query) ->
    $.get "/sites/search.json", query
  updateProperty: (siteId, data, options = {}) ->
    requestOptions = _.merge({
      type: "POST"
      url: "/sites/#{siteId}/update_property.json"
      data: data
    }, options)
    $.ajax requestOptions

Resmap.Api.Gateways =
  all: ->
    $.get "/gateways.json"

Resmap.Api.Memberships =
  collectionsIAdmin: (options = {}) ->
    $.get "/memberships/collections_i_admin.json", options
