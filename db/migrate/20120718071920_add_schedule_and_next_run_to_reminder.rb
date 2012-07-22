class AddScheduleAndNextRunToReminder < ActiveRecord::Migration
  def change
    add_column :reminders, :schedule, :text
    add_column :reminders, :next_run, :datetime
  end
end
