class AddHistoryToLayers < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TABLE layer_histories LIKE layers;
    SQL
    add_column :layer_histories, :valid_since, :datetime
    add_column :layer_histories, :valid_to, :datetime
    add_column :layer_histories, :layer_id, :integer
    add_index :layer_histories, :layer_id

    Layer.find_each do |layer|
      layer.create_history unless layer.current_history
    end
  end

  def down
    drop_table :layer_histories
  end
end
