class CreateReminders < ActiveRecord::Migration
  def change
    create_table :reminders do |t|
      t.string :name
      t.date :reminder_date
      t.text :reminder_message
      t.references :repeat
      t.references :collection

      t.timestamps
    end
    add_index :reminders, :repeat_id
    add_index :reminders, :collection_id
  end
end
