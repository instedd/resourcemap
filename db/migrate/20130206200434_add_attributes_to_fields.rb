class AddAttributesToFields < ActiveRecord::Migration
  def change
    add_column :fields, :attributes, :text
  end
end
