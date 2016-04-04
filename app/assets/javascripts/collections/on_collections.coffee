collectionsCallbacks = []
window.onCollections = (callback) -> collectionsCallbacks.push(callback)
window.runCollectionsCallbacks = -> callback() for callback in collectionsCallbacks
$ -> runCollectionsCallbacks() if $('#collections-main').length > 0
