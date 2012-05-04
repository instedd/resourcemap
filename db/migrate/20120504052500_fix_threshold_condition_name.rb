class FixThresholdConditionName < ActiveRecord::Migration
  def change
    rename_column :thresholds, :condition, :conditions
  end
end
