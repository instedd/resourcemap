require 'uuidtools'

class EliminateDuplicatedIds < ActiveRecord::Migration

	# In some cases previous migration generated some duplicated uuids inside the same collection
  def up
  	while(true)
  		duplicated_groups = Site.find(:all, :group => [:collection_id, :uuid], :having => "count(*) > 1" )
      puts "#{duplicated_groups.count} groups of duplicated uuid inside the same collection found"
  		if duplicated_groups.count == 0
  			break 
  		end
			duplicated_groups.each do |duplicated_group|
        duplicated_sites = duplicated_group.collection.sites.where(uuid: duplicated_group.uuid)
        duplicated_sites.each do |s|
          s.mute_activities = true
  			  s.uuid = UUIDTools::UUID.random_create.to_s
          s.save(:validate => false)
        end

        duplicated_sites.each do |site|
          site.histories.update_all ["uuid = ?", site.uuid]
        end
			end
		end
  end

  def down
  end
end
