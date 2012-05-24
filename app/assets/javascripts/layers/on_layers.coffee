window.onLayers ?= (callback) -> $(-> callback() if $('#layers-main').length > 0)
