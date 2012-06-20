onReminders ->
  class @Reminder 
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @reminder_date = ko.observable data?.reminder_date
      @reminder_time = ko.observable data?.reminder_date
      @reminder_datetime = ko.computed =>
        @reminder_date() + " " + @reminder_time()
      @reminder_message = ko.observable data?.reminder_message
      @repeat_id = ko.observable data?.repeat_id
      @repeat = ko.observable new Repeat(data?.repeat)
      @collection_id = ko.observable data?.collection_id
      if data?.sites
        @sites = ko.observableArray $.map(data.sites, (site) -> new Site(site))
      else 
        @sites = ko.observableArray([])
      @nameError = ko.computed =>
        if $.trim(@name()).length > 0 
          return null
        else
          return "Reminder's name is missing"
      @sitesError = ko.computed =>
        if @sites().length > 0
          return null
        else
          return "Sites is missing"
      @reminderDateError =ko.computed =>
        if $.trim(@reminder_date()).length > 0
          return null
        else
          return "Reminder's date is missing"

      @reminderMessageError = ko.computed =>
        if $.trim(@reminder_message()).length > 0
          return null
        else
          return "Reminder's message is missing"

      @error = ko.computed =>
        errorMessage = @nameError() || @sitesError() || @reminderDateError() || @reminderMessageError()
        if errorMessage then "Can't save: " + errorMessage else ""

      @valid = ko.computed => !@error()
      
    toJSON: =>
      id: @id()
      name: @name()
      reminder_date: @reminder_datetime()
      reminder_message: @reminder_message()
      repeat_id: @repeat_id()
      collection_id: @collection_id()
      sites: $.map(@sites(), (x) -> x.id)

    getSitesRepeatLabel: =>
      siteLabel = ""
      if @sites().length > 0 
        for i in [0...@sites().length-1]
          siteLabel = siteLabel + @sites()[i].name + " and "

        siteLabel = @repeat().name() + " for " + siteLabel + @sites()[@sites().length-1].name
        
