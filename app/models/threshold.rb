class Threshold < ActiveRecord::Base
  belongs_to :collection
  validates :priority, :presence => true
  validates :color, :presence => true
  
  serialize :condition, Hash

end
