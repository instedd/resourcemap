class AddLatAndLngToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :lat, :decimal, :precision => 10, :scale => 6
    add_column :collections, :lng, :decimal, :precision => 10, :scale => 6
  end
end
