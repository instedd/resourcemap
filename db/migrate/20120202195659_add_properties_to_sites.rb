class AddPropertiesToSites < ActiveRecord::Migration
  def change
    add_column :sites, :properties, :text
  end
end
