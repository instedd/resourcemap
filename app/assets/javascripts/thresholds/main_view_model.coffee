onThresholds ->
  class @MainViewModel
    constructor: (@collectionId) ->
      @fields = ko.observableArray()
      @emailMembers = ko.observableArray() 
      @messageMembers  = ko.observableArray()
      @selectedEmailMembersId = ko.observableArray()
      @selectedMessageMembersId = ko.observableArray()
      @compareFields = ko.observableArray()
      @thresholds = ko.observableArray([])
      @sites = ko.observableArray([])
      @currentThreshold = ko.observable()
      @saving = ko.observable(false)
      @isReady = ko.observable(false)
      @isSendNotification = ko.observable("false")
    
    addThreshold: =>
      threshold = new Threshold ord: @nextOrd(), is_all_site: "true", is_all_condition: "true"
      threshold.addNewCondition()
      @currentThreshold threshold
      @thresholds.push threshold

    editThreshold: (threshold) =>
      @originalThreshold = new Threshold(threshold.toJSON())
      @currentThreshold threshold

    loadSites: (callback) ->
      $.get "/collections/#{@collectionId}/sites", (sites) ->
        callback $.map sites, (site) => site.name

      
    saveThreshold: =>
      @saving(true)

      json = threshold: @currentThreshold().toJSON()
      if @currentThreshold().id()
        json._method = 'put'
        $.post "/collections/#{@collectionId}/thresholds/#{@currentThreshold().id()}.json", json, @saveThresholdCallback
      else
        $.post "/collections/#{@collectionId}/thresholds.json", json, @saveThresholdCallback

    saveThresholdCallback: (data) =>
      @currentThreshold().id(data?.id)
      @currentThreshold null
      delete @originalThreshold
      @saving(false)

    cancelThreshold: =>
      if @currentThreshold().id()
        @thresholds.replace @currentThreshold(), @originalThreshold
      else
        @thresholds.remove @currentThreshold()
      @currentThreshold null
      delete @originalThreshold

    deleteThreshold: (threshold) =>
      if window.confirm 'Are you sure to delete threshold?'
        @deletedThreshold = threshold
        $.post "/collections/#{@collectionId}/thresholds/#{threshold.id()}.json", { _method: 'delete' }, @deleteThresholdCallback

    deleteThresholdCallback: =>
      @thresholds.remove @deletedThreshold
      delete @deletedThreshold

    findField: (esCode) =>
      return field for field in @fields() when field.esCode() == esCode

    nextOrd: =>
      ord = 0
      for threshold in @thresholds()
        ord = threshold.ord() if threshold.ord() > ord
      ord += 1

    moveThresholdDown: (threshold) =>
      index = @thresholds.indexOf(threshold)
      @swapThresholdsOrder threshold, @thresholds()[index+1] if index < @thresholds().length - 1

    moveThresholdUp: (threshold) =>
     index = @thresholds.indexOf(threshold)
     @swapThresholdsOrder(threshold, @thresholds()[index-1]) if index > 0

    swapThresholdsOrder: (thresholds...) =>
      order = $.map thresholds, (threshold) -> threshold.ord()
      $.each thresholds, (i, threshold) => threshold.setOrder order.pop(), @setThresholdOrderCallback
      @refresh()

    setThresholdOrderCallback: (data) =>

    refresh: => @thresholds.sort (x, y) -> x.ord() > y.ord() ? -1 : 1
