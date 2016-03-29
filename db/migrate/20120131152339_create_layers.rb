class CreateLayers < ActiveRecord::Migration
  def change
    create_table :layers do |t|
      t.integer :collection_id
      t.string :name
      t.boolean :public

      t.timestamps :null => false
    end
  end
end
