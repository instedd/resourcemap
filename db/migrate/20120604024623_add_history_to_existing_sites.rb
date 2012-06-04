class AddHistoryToExistingSites < ActiveRecord::Migration
  def up
    Site.find_each do |site|
      sh = SiteHistory.find_by_site_id site.id
      if(!sh)
        shist = SiteHistory.create_from_site site
        shist.save
      end
    end
  end

  def down
  end
end
