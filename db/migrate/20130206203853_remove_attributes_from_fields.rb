class RemoveAttributesFromFields < ActiveRecord::Migration
  def up
    remove_column :fields, :attributes
  end

  def down
    add_column :fields, :attributes, :text
  end
end
