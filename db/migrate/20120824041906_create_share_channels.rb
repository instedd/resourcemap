class CreateShareChannels < ActiveRecord::Migration
  def change
    create_table :share_channels do |t|
      t.integer :channel_id
      t.integer :collection_id
      t.boolean :status

      t.timestamps :null => false
    end
  end
end
