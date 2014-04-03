class RemovePublicToCollections < ActiveRecord::Migration
  def up
    remove_column :collections, :public
  end

  def down
    add_column :collections, :public, :boolean
  end
end
