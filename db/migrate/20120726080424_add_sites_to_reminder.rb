class AddSitesToReminder < ActiveRecord::Migration
  def change
    add_column :reminders, :sites, :text
  end
end
