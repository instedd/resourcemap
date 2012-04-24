$ ->
  module 'rm'

  rm.ThresholdEvent = class ThresholdEvent
    constructor: (@threshold) ->

  ### 
    ThresholdEvent Types 
  ###
  rm.ThresholdEvent.DESTROY = 'ThresholdEvent:DESTROY'
  rm.ThresholdEvent.CHANGE_PRIORITY = 'ThresholdEvent:CHANGE_PRIORITY'
