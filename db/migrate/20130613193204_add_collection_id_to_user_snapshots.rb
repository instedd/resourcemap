class AddCollectionIdToUserSnapshots < ActiveRecord::Migration
  def change
    add_column :user_snapshots, :collection_id, :integer
  end
end
