class RenameColumnNameInThreshold < ActiveRecord::Migration
  def up
    rename_column :thresholds, :property_name, :name
  end

  def down
  end
end
