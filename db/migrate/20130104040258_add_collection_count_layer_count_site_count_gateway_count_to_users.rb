class AddCollectionCountLayerCountSiteCountGatewayCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :collection_count, :integer, :default => 0
    add_column :users, :layer_count, :integer, :default => 0
    add_column :users, :site_count, :integer, :default => 0
    add_column :users, :gateway_count, :integer, :default => 0
  end
end
