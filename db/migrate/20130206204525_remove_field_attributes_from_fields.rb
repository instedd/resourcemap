class RemoveFieldAttributesFromFields < ActiveRecord::Migration
  def up
    remove_column :fields, :field_attributes
  end

  def down
    add_column :fields, :field_attributes, :text
  end
end
