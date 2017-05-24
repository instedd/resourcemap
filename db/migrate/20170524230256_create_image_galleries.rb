class CreateImageGalleries < ActiveRecord::Migration
  def change
    create_table :image_galleries do |t|
      t.integer :site_id
      t.integer :field_id
      t.text :images
    end
  end
end
