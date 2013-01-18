class @MembershipsViewModel
  initialize: (admin, memberships, layers) ->
    @selectedLayer = ko.observable()
    @layers = ko.observableArray $.map(layers, (x) -> new Layer(x))
    @memberships = ko.observableArray $.map(memberships, (x) -> new Membership(x))
    @admin = ko.observable admin

    layer.initializeLinks() for layer in @layers()
    membership.initializeLinks() for membership in @memberships()

    @groupBy = ko.observable("Users")
    @groupByOptions = ["Users", "Layers"]


  destroyMembership: (membership) =>
    if confirm("Are you sure you want to remove #{membership.userDisplayName()} from the collection?")
      $.post "/collections/#{collectionId}/memberships/#{membership.userId()}.json", {_method: 'delete'}, =>
        @memberships.remove membership
