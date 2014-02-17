class AddAnonymousUserPermissionToLayerHistories < ActiveRecord::Migration
  def change
    add_column :layer_histories, :anonymous_user_permission, :string, :default => "none"
  end
end
