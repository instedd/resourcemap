class RemoveIsManualConfigurationIsShareShareCollectionsFromChannel < ActiveRecord::Migration
  def up
    remove_column :channels, :is_manual_configuration
    remove_column :channels, :is_share
    remove_column :channels, :share_collections
  end

  def down
    add_column :channels, :is_manual_configuration, :boolean
    add_column :channels, :is_share, :boolean
    add_column :channels, :share_collections, :text
  end
end
