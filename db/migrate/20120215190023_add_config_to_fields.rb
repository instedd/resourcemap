class AddConfigToFields < ActiveRecord::Migration
  def change
    add_column :fields, :config, :text
  end
end
