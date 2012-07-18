class AddRuleToRepeat < ActiveRecord::Migration
  def change
    add_column :repeats, :rule, :text
  end
end
