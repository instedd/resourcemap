class RemindersSite < ActiveRecord::Base
  belongs_to :reminder
  belongs_to :site
end
