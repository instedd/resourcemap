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
      fh = FieldHistory.find_by_field_id field.id
      unless fh
        fhist = field.create_history
        fhist.save
      end
    end

  end

  def down
    drop_table :field_histories
  end
end
