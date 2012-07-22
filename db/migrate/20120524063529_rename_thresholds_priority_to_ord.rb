class RenameThresholdsPriorityToOrd < ActiveRecord::Migration
  def change
    rename_column :thresholds, :priority, :ord
  end
end
