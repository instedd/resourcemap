class SiteHistory < ActiveRecord::Base
  belongs_to :site

  serialize :properties, Hash

  def self.create_from_site(site)
    self.create(:collection_id => site.collection_id, :name => site.name, :lat =>site.lat, :lng => site.lng, :parent_id => site.parent_id, :hierarchy => site.hierarchy, :properties => site.properties, :location_mode => site.location_mode, :id_with_prefix => site.id_with_prefix, :valid_since => Time.now, :valid_to => nil, :site_id => site.id)

  end

  def self.get_current_value(site)
    self.first(:conditions => "site_id = #{site.id} AND valid_to IS NULL")
  end

  def set_valid_to(date)
    self.valid_to = date
    self.save
  end
end