class DropSiteMemberships < ActiveRecord::Migration
  def up
    begin
      drop_table :site_memberships
    rescue; say 'site_memberships table is already deleted.' ;end
  end
end
