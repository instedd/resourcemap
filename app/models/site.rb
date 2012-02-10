class Site < ActiveRecord::Base
  include Site::GeomConcern
  include Site::TireConcern

  belongs_to :collection
  belongs_to :parent, :foreign_key => 'parent_id', :class_name => name

  has_many :sites, :foreign_key => 'parent_id', :class_name => name

  serialize :properties, Hash
end
