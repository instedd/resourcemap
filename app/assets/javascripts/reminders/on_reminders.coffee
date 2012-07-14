window.onReminders ?= (callback) -> $(-> callback() if $('#reminders-main').length > 0)
