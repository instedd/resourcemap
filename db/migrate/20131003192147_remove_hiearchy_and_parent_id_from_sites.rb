class RemoveHiearchyAndParentIdFromSites < ActiveRecord::Migration
  def change
    remove_column :sites, :parent_id
    remove_column :sites, :hierarchy

    remove_column :site_histories, :parent_id
    remove_column :site_histories, :hierarchy
  end
end
