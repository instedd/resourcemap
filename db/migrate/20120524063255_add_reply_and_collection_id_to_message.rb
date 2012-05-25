class AddReplyAndCollectionIdToMessage < ActiveRecord::Migration
  def change
    add_column :messages, :reply, :text

    add_column :messages, :collection_id, :integer

  end
end
