class Site < ActiveRecord::Base
  belongs_to :collection
  belongs_to :parent, :foreign_key => 'parent_id', :class_name => name

  has_many :sites, :foreign_key => 'parent_id'
end
