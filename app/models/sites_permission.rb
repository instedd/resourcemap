class SitesPermission < ActiveRecord::Base
  belongs_to :membership
  serialize :some_sites, Array

  def as_json(options = {})
    super options.merge({except: [:id, :membership_id, :created_at, :updated_at]})
  end
end
