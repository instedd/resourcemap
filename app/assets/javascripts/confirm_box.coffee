@initConfirm = (action_code) ->
  show_confirm = =>
    $("##{action_code}-collapsed").hide()
    $("##{action_code}-expanded").show()
    false

  hide_confirm = =>
    $("##{action_code}-expanded").hide()
    $("##{action_code}-collapsed").show()
    false

  $("##{action_code}-collapsed").click show_confirm

  $("##{action_code}-collapse-button").click hide_confirm

  $("##{action_code}-cancel").click hide_confirm
