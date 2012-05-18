class CreateSiteReminders < ActiveRecord::Migration
  def change
    create_table :site_reminders do |t|
      t.references :reminder
      t.references :site

      t.timestamps
    end
    add_index :site_reminders, :reminder_id
    add_index :site_reminders, :site_id
  end
end
