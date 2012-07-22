class AddPluginsToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :plugins, :text
  end
end
