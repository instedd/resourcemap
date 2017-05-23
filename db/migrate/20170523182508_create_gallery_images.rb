class CreateGalleryImages < ActiveRecord::Migration
  def change
    create_table :gallery_images do |t|
      t.integer :field_id
      t.string :guid, nullable: :false, limit: 255
      t.binary :data, nullable: :false, limit: 10.megabyte

      t.timestamps
    end

    add_index "gallery_images", ["field_id"], name: "index_gallery_images_on_field_id"
    add_index "gallery_images", ["guid"], name: "index_gallery_images_on_guid", unique: true
  end
end
