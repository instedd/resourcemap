#= require models/threshold

$ ->
  module 'rm'

  rm.ThresholdsViewModel = class ThresholdsViewModel
    constructor: () ->
      @thresholds = ko.observableArray()
