class CreateSitesPermissions < ActiveRecord::Migration
  def change
    create_table :sites_permissions do |t|
      t.integer :membership_id
      t.string :type
      t.boolean :all_sites
      t.text :some_sites

      t.timestamps
    end
  end
end
