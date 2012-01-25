class CreateSites < ActiveRecord::Migration
  def change
    create_table :sites do |t|
      t.integer :collection_id
      t.string :name
      t.decimal :lat, :precision => 10, :scale => 6
      t.decimal :lng, :precision => 10, :scale => 6
      t.integer :parent_id
      t.string :hierarchy

      t.timestamps
    end
  end
end
