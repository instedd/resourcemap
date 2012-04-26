class Site < ActiveRecord::Base
  include Activity::AwareConcern
  include Site::ActivityConcern
  include Site::GeomConcern
  include Site::TireConcern

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

  def level
    hierarchy.blank? ? 1 : hierarchy.count(',') + 2
  end
end
