class AddSitsAndIsAllConditionToThresholds < ActiveRecord::Migration
  def change
    add_column :thresholds, :sites, :text

    add_column :thresholds, :is_all_condition, :boolean

  end
end
