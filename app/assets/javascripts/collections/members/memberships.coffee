@initMemberships = (userId, collectionId, admin, layers) ->
  window.userId = userId

  $.get "/collections/#{collectionId}/memberships.json", (memberships) ->
    window.model = new MembershipsViewModel
    window.model.initialize admin, memberships, layers
    ko.applyBindings window.model

    $member_email = $('#member_email')

    createMembership = (email = $member_email.val()) ->
      if $.trim(email).length > 0
        $.post "/collections/#{collectionId}/memberships.json", {email: email}, (data) ->
          if data.status == 'added'
            new_member = new Membership(user_id: data.user_id, user_display_name: data.user_display_name)
            new_member.initializeLinks()
            window.model.memberships.push new_member
            $member_email.val('')

    $member_email.autocomplete
      source: (term, callback) ->
        $.ajax "/collections/#{collectionId}/memberships/invitable.json?#{$.param term}",
          success: (data) ->
            if data.length == 0
              callback(['No users found'])
              $('a', $member_email.autocomplete('widget')).attr('style', 'color: red')
            else
              callback(data)
      select: (event, ui) ->
        if(ui.item.label == 'No users found')
          event.preventDefault()
        else
          createMembership(ui.item.label)
      appendTo: '#autocomplete_container'

    $member_email.keydown (event) ->
      if event.keyCode == 13
        createMembership()

    $('#add_member').click -> createMembership()

    $('.hidden-until-loaded').show()
