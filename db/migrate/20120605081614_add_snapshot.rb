class AddSnapshot < ActiveRecord::Migration
  def change
    create_table :snapshots do |t|
      t.string :name
      t.datetime :date
      t.integer :collection_id

      t.timestamps :null => false
    end
  end
end
