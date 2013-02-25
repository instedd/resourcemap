class AddColumnQuotaToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :quota, :integer, :default => 0
  end
end
