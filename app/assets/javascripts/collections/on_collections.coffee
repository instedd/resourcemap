window.onCollections ?= (callback) -> $(-> callback() if $('#collections-main').length > 0)
