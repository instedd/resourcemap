$ ->
  module 'rm'

  # Global settings
  rm['settings'] = {}

  rm.bootstrap = ->
    systemEvent = new rm.SystemEvent
    rm.EventDispatcher.trigger rm.SystemEvent.GLOBAL_MODELS, systemEvent
    rm.EventDispatcher.trigger rm.SystemEvent.INITIALIZE, systemEvent

  rm.set = (settings) ->
    for key, value of settings
      rm['settings'][key] = value

  rm.get = (key) ->
    rm['settings']?[key]
