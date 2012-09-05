onSiteMemberships ->
  class @MainViewModel
    constructor: (@collectionId) ->
      @memberships = ko.observableArray([])
