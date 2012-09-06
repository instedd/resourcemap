onSiteMemberships ->
  class @Membership
    constructor: (@field, data) ->
      @collectionId = data.collection_id

      @canView = ko.observable data?.view_access
      @canUpdate = ko.observable data?.update_access
      @canDelete = ko.observable data?.delete_access

      @canView.subscribe (value) => @setAccess 'view_access', value
      @canUpdate.subscribe (value) => @setAccess 'update_access', value
      @canDelete.subscribe (value) => @setAccess 'delete_access', value

    setAccess: (type, access) ->
      $.post "/plugin/site_memberships/collections/#{@collectionId}/site_memberships/set_access", access: access, type: type, field_id: @field.id
