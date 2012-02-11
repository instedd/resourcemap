class AddLocationModeToSites < ActiveRecord::Migration
  def change
    add_column :sites, :location_mode, :string, :limit => 10, :default => :automatic
  end
end
