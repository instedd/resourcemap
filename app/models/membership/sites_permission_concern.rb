module Membership::SitesPermissionConcern
  extend ActiveSupport::Concern

  def update_sites_permission(sites_permission = {})
    sites_permission.each do |type, permission|
      if permission[:some_sites].is_a? Hash
        permission[:some_sites] = permission[:some_sites].values
      elsif not permission[:some_sites]
        permission[:some_sites] = []
      end

      self.find_or_build_sites_permission(type).update_attributes permission
    end
  end

  def find_or_build_sites_permission(type)
    send "#{type.to_s}_sites_permission" or send "build_#{type.to_s}_sites_permission"
  end

  def sites_permission
    permission = { read: read_sites_permission, write: write_sites_permission }
    permission = { read: build_read_sites_permission, write: build_write_sites_permission } if admin
    permission
  end
end

{:write=>{:all_sites=>false, :some_sites=>[{:id=>1, :name=>"Bayon clinic"}]}}
{"write"=>{"all_sites"=>"false", "some_sites"=>{"0"=>{"id"=>"5", "name"=>"Carlos Casares"}}}}
