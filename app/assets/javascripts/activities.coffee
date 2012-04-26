@initActivities = ->
  DESCRIPTION_LENGTH = 100

  class Activity
    constructor: (data) ->
      @id = ko.observable data?.id
      @collection = ko.observable data?.collection
      @user = ko.observable data?.user
      @description = ko.observable data?.description
      @createdAt = ko.observable data?.created_at
      @expanded = ko.observable false
      @canBeExpanded = ko.computed => @description().length > DESCRIPTION_LENGTH

      @displayedDescription = ko.computed =>
        if !@canBeExpanded() || @expanded()
          @description()
        else
          "#{@description().substring(0, DESCRIPTION_LENGTH)}..."

    expand: => @expanded(true)

  class ActivitiesViewModel
    constructor: (activities) ->
      @activities = ko.observableArray []
      @hasMore = ko.observable true
      @loading = ko.observable false
      @pushActivities activities

    pushActivities: (activities) ->
      if activities.length == 25
        activities = activities.slice(0, activities.length - 1)
      else
        @hasMore false

      @activities.push new Activity(activity) for activity in activities

    loadMore: ->
      @loading(true)

      lastId = @activities()[@activities().length - 1].id()

      $.get "/activity.json?before_id=#{lastId}", {}, (activities) =>
        @pushActivities activities
        @loading(false)

    refreshTimeago: => $('.timeago').timeago()

  $.get "/activity.json", {}, (activities) =>
    window.model = new ActivitiesViewModel(activities)
    ko.applyBindings window.model

    window.model.refreshTimeago()
