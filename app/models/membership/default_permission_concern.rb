module Membership::DefaultPermissionConcern
  extend ActiveSupport::Concern

  included do
    after_create :create_default_associations
  end

  def action_for_name_permission
    if admin
      "update"
    else
      name_permission.action
    end
  end

  def action_for_location_permission
    if admin
      "update"
    else
      location_permission.action
    end
  end

  def create_default_associations
    create_name_permission action: 'read'
    create_location_permission action: 'read'
  end

end
