onReminders -> 
  class @MainViewModel
    constructor: (collectionId) ->
      @reminders        = ko.observableArray()
      @repeats          = ko.observableArray()
      @sites            = ko.observableArray()
      @currentReminder  = ko.observable()
      @collectionId     = ko.observable collectionId
      @isSaving         = ko.observable false

    showAddReminder: =>
      reminder = new Reminder collection_id: @collectionId()
      @currentReminder reminder
      @reminders.push reminder
      
    editReminder: (reminder) =>
      @originalReminder = reminder.clone()
      @currentReminder reminder

    saveReminder: =>
      @isSaving true
      json = @currentReminder().toJson()
      if @currentReminder().id
        $.post "/plugin/reminders/collections/#{@collectionId()}/reminders/#{@currentReminder().id}.json", reminder: json, _method: 'put', @saveReminderCallback
      else
        $.post "/plugin/reminders/collections/#{@collectionId()}/reminders.json", reminder: json, @saveReminderCallback
    
    saveReminderCallback: (data) =>
      @currentReminder().id = data.id
      @currentReminder null
      @isSaving false

    cancelReminder: =>
      if @currentReminder().id?
        @reminders.replace @currentReminder(), @originalReminder
      else
        @reminders.remove @currentReminder()
      @currentReminder(null)
      
    deleteReminder: (reminder) =>
      if window.confirm 'Are you sure to delete reminder'
        @deletedReminder = reminder
        $.post "/plugin/reminders/collections/#{@collectionId()}/reminders/#{reminder.id}.json", _method: 'delete', @deleteReminderCallback

    deleteReminderCallback: =>
      @reminders.remove @deletedReminder
      delete @deletedReminder

    onOffEnable: (reminder) =>
      reminder.setStatus true, @reminderStatusCallback

    onOffDisable: (reminder) =>
      reminder.setStatus false, @reminderStatusCallback

    reminderStatusCallback: (data) =>
    
    findRepeat: (id) =>
      return repeat for repeat in @repeats() when repeat.id() == id
