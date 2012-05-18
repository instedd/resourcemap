class AddIdWithPrefixToSites < ActiveRecord::Migration
  def change
    add_column :sites, :id_with_prefix, :string

  end
end
