class CreateSiteMemberships < ActiveRecord::Migration
  def change
    create_table :site_memberships do |t|
      t.references :collection
      t.references :field
      t.boolean :view
      t.boolean :update
      t.boolean :delete

      t.timestamps
    end
  end
end
