@initMemberships = (collectionId) ->
  createMembership = (email = $member_email.val()) ->
    if $.trim(email).length > 0
      $.post "/collections/#{collectionId}/memberships.json", {email: email}, (data) ->
        window.location.reload() if data == 'added'

  $member_email = $('#member_email')
  $member_email.autocomplete
    source: "/collections/#{collectionId}/memberships/invitable.json"
    select: (event, ui) -> createMembership(ui.item.label)

  $member_email.keydown (event) ->
    if event.keyCode == 13
      createMembership()

  $('#add_member').click -> createMembership()
