class RemovePublicFromLayers < ActiveRecord::Migration
  def up
    remove_column :layers, :public
  end

  def down
    add_column :layers, :public, :boolean
  end
end
