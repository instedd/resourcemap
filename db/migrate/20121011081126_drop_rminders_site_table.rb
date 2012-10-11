class DropRmindersSiteTable < ActiveRecord::Migration
  def up
    drop_table :reminders_sites 
  end

  def down
  end
end
