class CreateLayerMemberships < ActiveRecord::Migration
  def change
    create_table :layer_memberships do |t|
      t.integer :collection_id
      t.integer :user_id
      t.integer :layer_id
      t.boolean :read, :default => false
      t.boolean :write, :default => false

      t.timestamps
    end
  end
end
