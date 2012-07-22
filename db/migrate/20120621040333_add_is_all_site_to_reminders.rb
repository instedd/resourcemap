class AddIsAllSiteToReminders < ActiveRecord::Migration
  def change
    add_column :reminders, :is_all_site, :boolean
  end
end
