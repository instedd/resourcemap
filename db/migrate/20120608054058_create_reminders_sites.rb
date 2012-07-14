class CreateRemindersSites < ActiveRecord::Migration
  def change
    create_table :reminders_sites do |t|
      t.references :reminder
      t.references :repeat

      t.timestamps
    end
    add_index :reminders_sites, :reminder_id
    add_index :reminders_sites, :repeat_id
  end
end
