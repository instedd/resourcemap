class AddColumnToChannel < ActiveRecord::Migration
  def change
    add_column :channels, :basic_setup, :boolean
    add_column :channels, :advanced_setup, :boolean
    add_column :channels, :national_setup, :boolean
  end
end
