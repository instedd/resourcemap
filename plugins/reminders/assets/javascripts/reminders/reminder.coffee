onReminders ->
  class @Reminder 
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @isAllSites = ko.observable data.is_all_site ? true
      @targetFor = ko.computed
        read: -> if @isAllSites() then 'all_sites' else 'some_sites'
        write: (value) -> 
          @isAllSites switch value
            when 'all_sites' then true
            when 'some_sites' then false
            else true
        owner: @

      seperator = ''
      if data.reminder_date?.indexOf("T") > 0
        seperator = 'T'
      else
        seperator = ' '
      @reminder_date = ko.observable data?.reminder_date?.split(seperator)[0]
      @reminder_time = ko.observable data?.reminder_date?.split(seperator)[1].substring(0,5)
      @reminder_datetime = ko.computed =>
        @reminder_date() + " " + @reminder_time()
      @reminder_message = ko.observable data?.reminder_message
      @repeat = ko.observable window.model.findRepeat(data?.repeat_id)

      @collection_id = ko.observable data?.collection_id
      
      if @isAllSites()
        @sites = ko.observableArray []
      else
        @sites = ko.observableArray $.map(data?.sites ? [], (site) -> new Site(site))
      
      @nameError = ko.computed =>
        if $.trim(@name()).length > 0 
          return null
        else
          return "Reminder's name is missing"
      @sitesError = ko.computed =>
        if !@isAllSites() and @sites().length == 0 then 'Sites is missing' else null

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
        # errorMessage = @nameError() || @reminderDateError() || @reminderMessageError()
        if errorMessage then "Can't save: " + errorMessage else ""

      @valid = ko.computed => !@error()
      
    toJSON: =>
      id: @id()
      name: @name()
      reminder_date: @reminder_datetime()
      reminder_message: @reminder_message()
      repeat_id: @repeat().id()
      collection_id: @collection_id()
      is_all_site: @isAllSites()
      sites: $.map(@sites(), (x) -> x.id) unless @isAllSites()

    toReminderJSON: =>
      id: @id()
      name: @name()
      reminder_date: @reminder_datetime()
      reminder_message: @reminder_message()
      repeat_id: @repeat().id()
      repeat: @repeat().toJSON()
      collection_id: @collection_id()
      is_all_site: @isAllSites()
      sites: $.map(@sites(), (site) -> site.toJSON()) unless @isAllSites()

    getSitesRepeatLabel: =>
      sites = if @isAllSites() then ["all sites"] else $.map @sites(), (site) => site.name
      detail = @repeat().name() + " for " + sites.join(",")
        
