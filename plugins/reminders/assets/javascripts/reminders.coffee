#= require reminders/on_reminders
#= require_tree ./reminders/.

onReminders ->

  match = window.location.toString().match(/\/collections\/(\d+)\/reminders/)
  collectionId = parseInt(match[1])
  
  window.model = new MainViewModel(collectionId)
  ko.applyBindings(window.model)
  
  $.get '/repeats.json', (data) ->
    repeats = $.map data, (repeat) ->
      new Repeat repeat
    window.model.repeats repeats

    $.get "/plugin/reminders/collections/#{collectionId}/reminders.json", (data) ->
      reminders = $.map data, (reminder) ->
        new Reminder reminder
      window.model.reminders reminders
  
  $('.hidden-until-loaded').show()


