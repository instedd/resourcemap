class Site < ActiveRecord::Base
  include Site::GeomConcern
  include Site::TireConcern
  include Activity::AwareConcern

  belongs_to :collection
  belongs_to :parent, foreign_key: 'parent_id', class_name: name
  has_many :sites, foreign_key: 'parent_id', class_name: name, dependent: :destroy

  serialize :properties, Hash

  before_create :store_hierarchy, :if => :parent_id
  def store_hierarchy
    self.hierarchy = if parent.hierarchy
                       "#{parent.hierarchy},#{self.parent_id}"
                     else
                       "#{self.parent_id}"
                     end
  end

  after_create :create_activity, :unless => :mute_activities
  def create_activity
    site_data = {name: name}
    site_data[:lat] = lat if lat
    site_data[:lng] = lng if lng
    if group?
      site_data[:location_mode] = location_mode
    else
      site_data[:properties] = properties if properties.present?
    end
    kind = group? ? 'group_created' : 'site_created'
    Activity.create! kind: kind, collection_id: collection.id, site_id: id, user_id: user.id, data: site_data
  end

  def level
    hierarchy.blank? ? 1 : hierarchy.count(',') + 2
  end
end
