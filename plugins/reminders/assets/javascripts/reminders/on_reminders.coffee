remindersCallbacks = []
window.onReminders = (callback) -> remindersCallbacks.push(callback)
window.runRemindersCallbacks = -> callback() for callback in remindersCallbacks
$ -> runRemindersCallbacks() if $('#reminders-main').length > 0
