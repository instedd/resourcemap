class AddAnonymousPermissionsToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :anonymous_name_permission, :string, :default => "none"
    add_column :collections, :anonymous_location_permission, :string, :default => "none"
  end
end
