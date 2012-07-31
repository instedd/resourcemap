class RemoveKindFromActivities < ActiveRecord::Migration
  def up
    remove_column :activities, :kind
  end

  def down
    add_column :activities, :kind, :string
    execute <<-SQL
      UPDATE activities SET kind = concat(item_type, '_', action)
    SQL
  end
end
