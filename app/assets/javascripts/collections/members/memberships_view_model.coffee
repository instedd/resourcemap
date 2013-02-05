class @MembershipsViewModel
  initialize: (admin, memberships, layers, collectionId) ->
    _self = @

    @collectionId = ko.observable(collectionId)

    @selectedLayer = ko.observable()
    @layers = ko.observableArray $.map(layers, (x) -> new Layer(x))

    @memberships = ko.observableArray $.map(memberships, (x) -> new Membership(_self, x))
    @admin = ko.observable admin

    @groupBy = ko.observable("Users")
    @groupByOptions = ["Users", "Layers"]


  destroyMembership: (membership) =>
    if confirm("Are you sure you want to remove #{membership.userDisplayName()} from the collection?")
      $.post "/collections/#{collectionId}/memberships/#{membership.userId()}.json", {_method: 'delete'}, =>
        @memberships.remove membership
