class CreateChannels < ActiveRecord::Migration
  def change
    create_table :channels do |t|
      t.string :name
      t.boolean :is_enable
      t.string :password
      t.integer :collection_id
      t.string :nuntium_channel_name
      t.boolean :is_manual_configuration
      t.boolean :is_share
      t.text :share_collections

      t.timestamps
    end
  end
end
