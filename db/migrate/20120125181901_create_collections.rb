class CreateCollections < ActiveRecord::Migration
  def change
    create_table :collections do |t|
      t.string :name
      t.text :description
      t.boolean :public

      t.timestamps :null => false
    end
  end
end
