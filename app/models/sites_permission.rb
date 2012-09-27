class SitesPermission < ActiveRecord::Base
  belongs_to :membership
  serialize :some_sites, Array
end
