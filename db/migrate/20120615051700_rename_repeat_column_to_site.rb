class RenameRepeatColumnToSite < ActiveRecord::Migration
  def change 
    rename_column :reminders_sites, :repeat_id, :site_id
  end

end
