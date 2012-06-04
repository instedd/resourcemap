window.onBulkUpdate ?= (callback) -> $(-> callback() if $('#bulk-update-main').length > 0)
