$ ->
  module 'rm'

  rm.EventDispatcher =
    listeners: {}

    bind: (eventType, callback) ->
      this.listeners[eventType] = [] unless this.listeners[eventType]
      this.listeners[eventType].push callback

    trigger: (eventType, eventData) ->
      if this.listeners[eventType]
        callback.apply(this, [eventData]) for callback in this.listeners[eventType]
