class AddVersionToSite < ActiveRecord::Migration
  def change
    add_column :sites, :version, :integer, default: 0
  end
end
