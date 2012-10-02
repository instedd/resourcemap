module Membership::SitesPermissionConcern
  extend ActiveSupport::Concern

  def update_sites_permission(sites_permission = {})
    sites_permission.each do |type, permission|
      permission[:some_sites] = permission[:some_sites].values if permission[:some_sites].is_a? Hash
      self.sites_permission(type).update_attributes permission
    end
  end

  def sites_permission(type)
    send "#{type.to_s}_sites_permission" or send "build_#{type.to_s}_sites_permission"
  end
end
