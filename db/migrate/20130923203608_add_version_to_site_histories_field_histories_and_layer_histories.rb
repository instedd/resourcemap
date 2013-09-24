class AddVersionToSiteHistoriesFieldHistoriesAndLayerHistories < ActiveRecord::Migration

  # For the moment existing histories wont have a version.
  def change
    add_column :site_histories, :version, :integer, default: 0
    add_column :field_histories, :version, :integer, default: 0
    add_column :layer_histories, :version, :integer, default: 0
  end
end
