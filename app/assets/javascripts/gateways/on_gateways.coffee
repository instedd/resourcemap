window.onGateways ?= (callback) ->  $(-> callback() if $('#gateways-main').length > 0)
