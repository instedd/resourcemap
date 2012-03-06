class Site < ActiveRecord::Base
  include Site::GeomConcern
  include Site::TireConcern

  belongs_to :collection, :touch => true
  belongs_to :parent, :foreign_key => 'parent_id', :class_name => name, :touch => true
  has_many :sites, :foreign_key => 'parent_id', :class_name => name, :dependent => :destroy

  serialize :properties, Hash

  before_create :store_hierarchy, :if => :parent_id

  def store_hierarchy
    parent_hierarchy = parent.hierarchy
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
