thresholdsCallbacks = []
window.onThresholds = (callback) -> thresholdsCallbacks.push(callback)
window.runThresholdsCallbacks = -> callback() for callback in thresholdsCallbacks
$ -> runThresholdsCallbacks() if $('#thresholds-main').length > 0
