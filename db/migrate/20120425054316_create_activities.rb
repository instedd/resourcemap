class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.string :kind
      t.integer :user_id
      t.integer :collection_id
      t.integer :layer_id
      t.integer :field_id
      t.integer :site_id
      t.text :data

      t.timestamps
    end
  end
end
