class AddAnonymousUserPermissionToLayers < ActiveRecord::Migration
  def change
    add_column :layers, :anonymous_user_permission, :string
  end
end
