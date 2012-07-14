class AddBoundingBoxToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :min_lat, :decimal, :precision => 10, :scale => 6
    add_column :collections, :min_lng, :decimal, :precision => 10, :scale => 6
    add_column :collections, :max_lat, :decimal, :precision => 10, :scale => 6
    add_column :collections, :max_lng, :decimal, :precision => 10, :scale => 6
  end
end
