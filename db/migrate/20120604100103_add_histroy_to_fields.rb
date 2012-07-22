class AddHistroyToFields < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TABLE field_histories LIKE fields;
    SQL
    add_column :field_histories, :valid_since, :datetime
    add_column :field_histories, :valid_to, :datetime
    add_column :field_histories, :field_id, :integer
    add_index :field_histories, :field_id

    Field.find_each do |field|
      field.create_history unless field.current_history
    end
  end

  def down
    drop_table :field_histories
  end
end
