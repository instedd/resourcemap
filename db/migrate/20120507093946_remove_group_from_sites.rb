class RemoveGroupFromSites < ActiveRecord::Migration
  def up
    remove_column :sites, :group
    [:min_lat, :max_lat, :min_lng, :max_lng, :min_zoom, :max_zoom].each do |column|
      remove_column :sites, column
    end
  end

  def down
    add_column :sites, :group, :boolean
    [:min_lat, :max_lat, :min_lng, :max_lng].each do |column|
      add_column :sites, column, :decimal, :precision => 10, :scale => 6
    end
    add_column :sites, :min_zoom, :integer
    add_column :sites, :max_zoom, :integer
  end
end
