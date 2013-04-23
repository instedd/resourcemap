require 'uuidtools'

class EliminateDuplicatedIds < ActiveRecord::Migration

	# In some cases previous migration generated some duplicated uuids inside the same collection
  def up
  	while(true)
  		duplicated_sites = Site.find(:all, :group => [:collection_id, :uuid], :having => "count(*) > 1" )
  		if duplicated_sites.count == 0
  			break 
  		end
			duplicated_sites.each do |s|
  			s.update_column(:uuid, UUIDTools::UUID.random_create.to_s)
			end
		end
  end

  def down
  end
end
