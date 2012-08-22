onReminders ->
  class @Reminder 
    constructor: (data) ->
      @id           = data?.id 
      @collectionId = data?.collection_id 
      @name         = ko.observable data?.name
      @enableCss    = ko.observable 'cb-enable'
      @disableCss   = ko.observable 'cb-disalbe'
      @isAllSites   = ko.observable data.is_all_site ? true
      @targetFor    = ko.computed
        read: -> if @isAllSites() then 'all_sites' else 'some_sites'
        write: (value) -> 
          @isAllSites switch value
            when 'all_sites' then true
            when 'some_sites' then false
            else true
        owner: @
      @sites            = ko.observableArray $.map data.sites ? [], (site) -> new Site site
      @sitesName        = ko.computed => $.map(@sites(), (site) -> site.name).join ', '
      @reminderDateTime = new ReminderDateTime data.reminder_date?.toDate() ? Date.today()
      @reminderDate     = ko.observable @reminderDateTime.getDate()
      @reminderTime     = ko.observable @reminderDateTime.getTime()
      @repeat           = ko.observable data?.repeat
      @repeatName       = ko.computed => @repeat()?.name()
      @reminderMessage  = ko.observable data?.reminder_message
      @status           = ko.observable data?.status
      @statusInit       = ko.computed =>
        if @status()
          @enableCss 'cb-enable selected'
          @disableCss 'cb-disable'
        else
          @enableCss 'cb-enable'
          @disableCss 'cb-disable selected'
      @nameError            = ko.computed => "Reminder's name is missing" if $.trim(@name()).length == 0
      @sitesError           = ko.computed => "Sites is missing" if !@isAllSites() and @sites().length == 0
      @reminderDateError    = ko.computed =>
        if @reminderDate().length == 0 then "Reminder's date is missing" 
        ## FIXME: To check for invalid reminderDate uncomment below line, but Phantomjs used in Jenkins consider 'YYYY-MM-DD' to be invalid date
        # else unless @reminderDate().toDate() then "Reminder's date is invalid"

      @reminderMessageError = ko.computed => "Reminder's message is missing" if $.trim(@reminderMessage()).length == 0

      @error = ko.computed => @nameError() ? @sitesError() ? @reminderDateError() ? @reminderMessageError()
      @valid = ko.computed => !@error()

    updateReminderDate: ->
      @reminderDateTime.setDate(@reminderDate()).setTime(@reminderTime())

    clone: =>
      new Reminder
        id                : @id
        name              : @name()
        is_all_site       : @isAllSites()
        reminder_date     : @reminderDate.toString()
        repeat            : @repeat()
        reminder_message  : @reminderMessage()
        collection_id     : @collectionId

    toJson: =>
      id: @id
      name: @name()
      reminder_date: @updateReminderDate().toString()
      reminder_message: @reminderMessage()
      repeat_id: @repeat().id()
      collection_id: @collectionId
      is_all_site: @isAllSites()
      sites: $.map(@sites(), (x) -> x.id) unless @isAllSites()
   
    getSitesRepeatLabel: =>
      sites = if @isAllSites() then ["all sites"] else $.map @sites(), (site) => site.name
      detail = @repeat().name() + " for " + sites.join(",")

    setStatus: (status, callback) ->
      @status status
      $.post "/plugin/reminders/collections/#{@collectionId}/reminders/#{@id}/set_status.json", {status: status}, callback
