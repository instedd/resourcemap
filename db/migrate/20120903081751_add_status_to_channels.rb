class AddStatusToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :status, :boolean
  end
end
