layersCallbacks = []
window.onLayers = (callback) -> layersCallbacks.push(callback)
window.runLayersCallbacks = -> callback() for callback in layersCallbacks
$ -> runLayersCallbacks() if $('#layers-main').length > 0
