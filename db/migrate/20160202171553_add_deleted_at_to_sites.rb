class AddDeletedAtToSites < ActiveRecord::Migration
  def change
    add_column :sites, :deleted_at, :datetime
    add_index :sites, :deleted_at
  end
end
