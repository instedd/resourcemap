class CreateRepeats < ActiveRecord::Migration
  def change
    create_table :repeats do |t|
      t.string :name
      t.integer :order

      t.timestamps :null => false
    end
  end
end
