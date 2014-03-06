class CollectionAnonymousNameLocationPermissions < ActiveRecord::Migration
  class Collection < ActiveRecord::Base
  end

  def up
    Collection.where(:public => true).find_each do |c|
      c.anonymous_name_permission = "read"
      c.anonymous_location_permission = "read"
      c.save!
    end
  end

  def down
    Collection.where(:public => true).find_each do |c|
      c.anonymous_name_permission = "none"
      c.anonymous_location_permission = "none"
      c.save!
    end
  end
end
