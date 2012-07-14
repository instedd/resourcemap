class RenameThresholdColorToIcon < ActiveRecord::Migration
  def up
    rename_column :thresholds, :color, :icon
  end

  def down
    rename_column :thresholds, :icon, :color
  end
end
