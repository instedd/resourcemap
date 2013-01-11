class RemoveIsManualConfigurationIsShareShareCollectionsFromChannel < ActiveRecord::Migration
  def up
    remove_column :channels, :is_manual_configuration, :is_share, :share_collections
  end

  def down
  end
end
