class RemoveCollectionIdFromChannels < ActiveRecord::Migration
  def up
    remove_column :channels, :collection_id 
  end

  def down
  end
end
