class AddBoundingBoxToSites < ActiveRecord::Migration
  def change
    [:min_lat, :max_lat, :min_lng, :max_lng].each do |column|
      add_column :sites, column, :decimal, :precision => 10, :scale => 6
    end
  end
end
