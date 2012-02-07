class RenameFolderToGroupInSites < ActiveRecord::Migration
  def change
    rename_column :sites, :folder, :group
  end
end
