class RenameRepeatColumnToSite < ActiveRecord::Migration
  def change 
    rename_column :reminders_sites, :repeat_id, :site_id
    remove_index :reminders_sites, :column => :repeat_id
    add_index :reminders_sites, :site_id
  end

end
