class SetSitesGroupDefaultValueToFalse < ActiveRecord::Migration
  def change
    change_column :sites, :group, :boolean, :default => false
    ActiveRecord::Base.connection.execute "update sites set `group` = 0 where `group` is null"
  end
end
