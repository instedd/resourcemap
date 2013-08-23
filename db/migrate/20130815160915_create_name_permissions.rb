class CreateNamePermissions < ActiveRecord::Migration
  def up
    create_table :name_permissions do |t|
      t.string :action, default: 'read'
      t.references :membership
      t.timestamps
    end

    add_index :name_permissions, :membership_id
  end

  def down
    drop_table :name_permissions
  end
end
