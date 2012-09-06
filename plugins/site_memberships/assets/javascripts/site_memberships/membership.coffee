onSiteMemberships ->
  class @Membership
    constructor: (@field, data) ->
      @collectionId = data.collection_id

      @canView = ko.observable data?.view_access
      @canUpdate = ko.observable data?.update_access
      @canDelete = ko.observable data?.delete_access

      @canView.subscribe (value) =>
        $.post "/plugin/site_memberships/collections/#{@collectionId}/site_memberships/set_access", access: value, type: 'view_access', field_id: @field.id
