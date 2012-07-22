class AddOrdToFields < ActiveRecord::Migration
  def change
    add_column :fields, :ord, :integer

  end
end
