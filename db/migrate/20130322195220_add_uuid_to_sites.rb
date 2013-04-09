require 'uuidtools'

class AddUuidToSites < ActiveRecord::Migration
	# Maybe this property should be defined in fred_api plugin, and be stored under site's properties
	# But this would imply creating a new Field type that behaves different than the others
  def up
  	add_column :sites, :uuid, :string
  	add_column :site_histories, :uuid, :string
  	Site.update_all ["uuid = ?", UUIDTools::UUID.random_create.to_s]
  	Site.all.each do |site|
  		site.histories.update_all ["uuid = ?", site.uuid]
		end
  end

  def down
    remove_column :sites, :uuid
    remove_column :site_histories, :uuid
  end
end
