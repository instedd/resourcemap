class Reminders::Plugin < Plugin

	collection_tab '/reminder_tab'

	routes {
		resources :collections do
			resources :reminders
		end
	}
end