channelsCallbacks = []
window.onChannels = (callback) -> channelsCallbacks.push(callback)
window.runChannelsCallbacks = -> callback() for callback in channelsCallbacks
$ -> runChannelsCallbacks() if $('#channels-main').length > 0
