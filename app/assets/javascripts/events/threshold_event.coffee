$ ->
  module 'rm'

  rm.ThresholdEvent = class ThresholdEvent
    constructor: (@threshold) ->

  ### 
    ThresholdEvent Types 
  ###
  rm.ThresholdEvent.DESTROY = 'ThresholdEvent:DESTROY'
  rm.ThresholdEvent.CREATE = 'ThresholdEvent:CREATE'
  rm.ThresholdEvent.SET_PRIORITY = 'ThresholdEvent:SET_PRIORITY'
