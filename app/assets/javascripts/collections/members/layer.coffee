class @Layer extends Expandable
  constructor: (data) ->
    super
    @id = ko.observable data?.id
    @name = ko.observable data?.name

  initializeLinks: =>
    @membershipLayerLinks = ko.observableArray $.map(window.model.memberships(), (x) => new MembershipLayerLink(x, @))
    @initializeAllReadAllWrite()
