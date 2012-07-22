class RemoveReminderDateFromReminder < ActiveRecord::Migration
  def change
    remove_column :reminders, :reminder_date
  end
end
