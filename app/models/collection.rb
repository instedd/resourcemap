class Collection < ActiveRecord::Base
  include CollectionTire

  validates_presence_of :name

  has_many :memberships
  has_many :users, :through => :memberships
  has_many :sites, :dependent => :destroy
  has_many :root_sites, :class_name => 'Site', :conditions => {:parent_id => nil}
  has_many :layers, :dependent => :destroy
  has_many :fields
end
