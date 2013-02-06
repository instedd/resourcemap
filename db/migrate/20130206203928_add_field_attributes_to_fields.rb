class AddFieldAttributesToFields < ActiveRecord::Migration
  def change
    add_column :fields, :field_attributes, :text
  end
end
