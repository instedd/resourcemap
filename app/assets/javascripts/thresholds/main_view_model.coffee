onThresholds ->
  class @MainViewModel
    constructor: (@collectionId) ->
      @fields = ko.observableArray()
      @thresholds = ko.observableArray([])
      @currentThreshold = ko.observable()
      @saving = ko.observable(false)
      @isReady = ko.observable(false)

    addThreshold: =>
      threshold = new Threshold ord: @nextOrd()
      @thresholds.push threshold
      @currentThreshold threshold

    editThreshold: (threshold) =>
      @originalThreshold = new Threshold(threshold.toJSON())
      @currentThreshold threshold

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
      @saving(false)

    cancelThreshold: =>
      if @currentThreshold().id()
        @thresholds.replace @currentThreshold(), @originalThreshold
      else
        @thresholds.remove @currentThreshold()
      @currentThreshold null

    deleteThreshold: (threshold) =>

    findField: (esCode) =>
      (field for field in @fields() when field.esCode() == esCode)[0]

    nextOrd: =>
      ord = 0
      for threshold in @thresholds()
        ord = threshold.ord() if threshold.ord() > ord
      ord += 1
