#= require models/threshold

$ ->
  module 'rm'

  rm.ThresholdsViewModel = class ThresholdsViewModel

    @Messages =
      DELETE_THRESHOLD: 'Are you sure to delete threshold?'

    constructor: (@collectionId) ->
      @thresholds = ko.observableArray()
      @currentThreshold = ko.observable() 
      @fieldsOption = [
        "bed"
        "hospital"
        "car garage"
        "petro station"
      ]

      @comparisonsOption = [
        comparison_value: "is less than"
        comparison_key: "lt"
      ,
        comparison_value: "is more than"
        comparison_key: "mt"
      ]

      @ofOption = [
        "a value of"
        "a percent of"
      ]

    deleteThreshold: (threshold) =>
      threshold.destroy() if confirm ThresholdsViewModel.Messages.DELETE_THRESHOLD

    addThreshold: () ->
      rm.thresholdsViewModel.currentThreshold().create()

    showAddThreshold: () ->
      defaultThreshold = 
        collection_id: @collectionId
        valueOforPercentOf: @ofOption[0]
        priority: @thresholds().length + 1 
        comp: @comparisonsOption[1]
        value: 10
        comparison: @comparisonsOption[0].comparison_key
        condition: {
          field: ko.observable(@fieldsOption[0])
          is: "lt" 
          value: ko.observable(10)
        }
        color: "#FFFFFF"

      threshold = new rm.Threshold defaultThreshold
      @thresholds.push threshold
      @currentThreshold(threshold)
