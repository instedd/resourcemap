onReminders -> 
  class @MainViewModel
    @State =
      LISTING: 'listing',
      ADDING_NEW: 'adding_new',
      EDITING: 'editing'

    constructor: (collectionId) ->
      @reminders= ko.observableArray()
      @repeats = ko.observableArray()
      @sites = ko.observableArray()
      @currentState = ko.observable MainViewModel.State.LISTING
      @currentReminder = ko.observable()
      @collectionId = ko.observable collectionId
      @isVisibleFormEntry = ko.computed =>
        return @currentState() != MainViewModel.State.LISTING

    showAddReminder: =>
      @currentState MainViewModel.State.ADDING_NEW
      @currentReminder new Reminder({})
 
    getTimes: =>
      times = []
      for i in [0...24]
        do ->
        times = times.concat ["#{i}:00","#{i}:30"]
      times

    saveReminder: =>
    
    loadSites: (callback) ->
      $.get "/collections/#{@collectionId()}/sites", (sites) ->
        callback $.map sites, (site) => site.name