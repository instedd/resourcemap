class AddFolderToSites < ActiveRecord::Migration
  def change
    add_column :sites, :folder, :boolean

  end
end
