$ ->
  module 'rm'

  rm.ThresholdEvent = class ThresholdEvent
    constructor: (@threshold) ->

  ### 
    ThresholdEvent Types 
  ###
  rm.ThresholdEvent.DESTROY = 'ThresholdEvent:DESTROY'
