class CreateThresholds < ActiveRecord::Migration
  def change
    create_table :thresholds do |t|
      t.integer :priority
      t.string :color
      t.text :condition
      t.integer :collection_id

      t.timestamps
    end
  end
end
