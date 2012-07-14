class CreatePrefixes < ActiveRecord::Migration
  def change
    create_table :prefixes do |t|
      t.string :version

      t.timestamps
    end
  end
end
