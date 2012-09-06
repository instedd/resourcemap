class CreateSiteMemberships < ActiveRecord::Migration
  def change
    create_table :site_memberships do |t|
      t.references :collection
      t.references :field
      t.boolean :view_access
      t.boolean :update_access
      t.boolean :delete_access

      t.timestamps
    end
  end
end
