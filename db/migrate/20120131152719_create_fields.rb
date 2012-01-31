class CreateFields < ActiveRecord::Migration
  def change
    create_table :fields do |t|
      t.integer :collection_id
      t.integer :layer_id
      t.string :name
      t.string :code
      t.string :kind

      t.timestamps
    end
  end
end
