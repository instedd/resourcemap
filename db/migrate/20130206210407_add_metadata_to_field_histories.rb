class AddMetadataToFieldHistories < ActiveRecord::Migration
  def change
    add_column :field_histories, :metadata, :text
  end
end
