onReminders ->
  class @Reminder 
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @reminder_date = ko.observable data?.reminder_date
      @reminder_message = ko.observable data?.reminder_message
      @repeat_id = ko.observable data?.repeat_id
      @collection_id = ko.observable data?.collection_id
      @sites = ko.observable()
      @nameError = ko.computed =>
        if $.trim(@name()).length > 0 
          return null
        else
          return "Reminder's name is missing"
      @sitesError = ko.computed =>
        if $.trim(@sites()).length > 0
          return null
        else
          return "Sites is missing"

      
    getSites: (text) =>
      $.get("/collections/#{@collection_id()}/sites?query=#{text}", (data)) ->
        @sites(data)

    error: =>
      errorMessage = @nameError() || @sitesError()
      if errorMessage then "Can't save: " + errorMessage else "" 


        #post: (reminder) =>
        #  $.post("/reminders", k)
