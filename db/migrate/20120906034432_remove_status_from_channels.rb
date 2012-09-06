class RemoveStatusFromChannels < ActiveRecord::Migration
  def up
    remove_column :channels, :status
  end

  def down
    add_column :channels, :status, :boolean
  end
end
