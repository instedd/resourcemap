class AddIconToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :icon, :string
  end
end
