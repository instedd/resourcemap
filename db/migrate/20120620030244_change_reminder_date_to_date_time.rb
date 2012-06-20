class ChangeReminderDateToDateTime < ActiveRecord::Migration
  def up
    change_table :reminders do |t|
      t.change :reminder_date, :datetime
    end
  end

  def down
    change_table :reminders do |t|
      t.change :reminder_date, :date
    end
  end
end
