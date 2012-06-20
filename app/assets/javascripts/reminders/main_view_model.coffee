onReminders -> 
  class @MainViewModel
    constructor: (collectionId) ->
      @reminders= ko.observableArray()
      @repeats = ko.observableArray()
      @sites = ko.observableArray()
      @currentReminder = ko.observable()
      @collectionId = ko.observable collectionId
      @isSaving = ko.observable false

    showAddReminder: =>
      reminder = new Reminder({collection_id: @collectionId()})
      @currentReminder reminder
      @reminders.push reminder
      
    editReminder: (reminder) =>
      @currentReminder reminder
 
    getTimes: =>
      times = []
      for i in [0...24]
        do ->
        times = times.concat ["#{i}:00","#{i}:30"]
      times

    saveReminder: =>
      @isSaving true
      json = reminder: @currentReminder().toJSON()
      if @currentReminder().id()
        json._method = 'put'
        $.post "/collections/#{@collectionId()}/reminders/#{@currentReminder().id()}.json", json, @saveReminderCallback
      else
        $.post "/collections/#{@collectionId()}/reminders.json", json, @saveReminderCallback
    
    saveReminderCallback: (data) =>
      @currentReminder().id(data.id)
      @currentReminder(null)
      @isSaving false

    # loadSites: (callback) ->
      # $.get "/collections/#{@collectionId()}/sites", (sites) ->
        # callback $.map sites, (site) => new Site site

    cancelReminder: =>
      if !@currentReminder().id()?
        @reminders.remove @currentReminder()
      @currentReminder(null)
      
    deleteReminder: (reminder) =>
      if window.confirm 'Are you sure to delete reminder'
        @deletedReminder = reminder
        $.post "/collections/#{@collectionId()}/reminders/#{reminder.id()}.json", { _method: 'delete' }, @deleteReminderCallback

    deleteReminderCallback: =>
      @reminders.remove @deletedReminder
      delete @deletedReminder
