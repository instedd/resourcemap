class AddOrdToLayers < ActiveRecord::Migration
  def change
    add_column :layers, :ord, :integer

  end
end
