class AddMetadataToFields < ActiveRecord::Migration
  def change
    add_column :fields, :metadata, :text
  end
end
