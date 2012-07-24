class Reminders::Plugin < Plugin

	collection_tab '/reminder_tab'

  schedule \
    every: "5m",
    class: "ReminderTask",
    queue: 'reminder_queue'

	routes {
		resources :collections do
			resources :reminders
		end
	}
end
