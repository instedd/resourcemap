onSiteMemberships ->
  class @Membership
    constructor: (@field, data) ->
      @collectionId = data.collection_id

      @canView = ko.observable data?.view
      @canUpdate = ko.observable data?.update
      @canDelete = ko.observable data?.delete
