class AddItemTypeAndActionToActivities < ActiveRecord::Migration
  def up
    add_column :activities, :item_type, :string
    add_column :activities, :action, :string

    execute <<-SQL
      UPDATE activities SET item_type = substring_index(kind, '_', 1), action = substring(kind, instr(kind, '_') + 1)
    SQL
  end

  def down
    remove_column :activities, :item_type
    remove_column :activities, :action
  end
end
