class GenerateDefaultPermissionsForNameAndLocationForExistingMemberships < ActiveRecord::Migration
  class NamePermission < ActiveRecord::Base
    belongs_to :membership
  end

  class LocationPermission < ActiveRecord::Base
    belongs_to :membership
  end

  class Membership < ActiveRecord::Base
    has_one :name_permission
    has_one :location_permission
  end

  def up
    Membership.find_each do |membership|
      NamePermission.create action: 'update', membership: membership
      LocationPermission.create action: 'update', membership: membership
    end
  end

  def down
    LocationPermission.destroy_all
    NamePermission.destroy_all
  end
end
