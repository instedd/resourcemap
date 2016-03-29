class CreateThresholds < ActiveRecord::Migration
  def change
    create_table :thresholds do |t|
      t.integer :priority
      t.string :color
      t.text :condition
      t.integer :collection_id

      t.timestamps :null => false
    end
  end
end
