class RemoveStatusFromShareChannels < ActiveRecord::Migration
  def up
    remove_column :share_channels, :status 
  end

  def down
  end
end
