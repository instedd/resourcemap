#= require models/threshold

$ ->
  module 'rm'

  rm.ThresholdsViewModel = class ThresholdsViewModel
    constructor: () ->
      @thresholds = ko.observableArray()
      @fieldsOption = [
        field: "bed"
      ,
        field: "hospital"
      ,
        field: "car garage"
      ,
        field: "petro station"
      ]

      @conditionsOption = [
        condition: "is less than"
      ,
        condition: "is more than"
      ]

      @comparesOption = [
        compare: "a value of"
      ,
        compare: "a percent of"
      ]

      @compares = ko.observable(@comparesOption[0]) 
      @fields = ko.observable(@fieldsOption[0])
      @conditions = ko.observable(@conditionsOption[0])
      @colors = ko.observable("orange") 
      @values = ko.observable(10)

    addThreshold: () ->
      threshold  = 
        priority: @thresholds().length + 1
        condition: {
          field: @fields().field
          is: @conditions().condition
          value: @values()
        }
        color: @colors()
      @thresholds.push new rm.Threshold threshold
