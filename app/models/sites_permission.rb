class SitesPermission < ApplicationRecord
  belongs_to :membership
  serialize :some_sites, Array

  after_save :touch_membership_lifespan
  after_destroy :touch_membership_lifespan

  def as_json(options = {})
    super options.merge({except: [:id, :membership_id, :created_at, :updated_at]})
  end
end
