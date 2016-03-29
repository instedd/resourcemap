class CreateLocationPermissions < ActiveRecord::Migration
  def up
    create_table :location_permissions do |t|
      t.string :action, default: 'read'
      t.references :membership
      t.timestamps :null => false
    end

    add_index :location_permissions, :membership_id
  end

  def down
    drop_table :location_permissions
  end
end
