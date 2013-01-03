class RemoveColumnPluginsFromCollections < ActiveRecord::Migration
  def up
    remove_column :collections, :plugins
  end

  def down
    add_column :collections, :plugins
  end
end
