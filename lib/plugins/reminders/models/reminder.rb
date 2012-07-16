class Reminder < ActiveRecord::Base
  belongs_to :collection
  belongs_to :repeat
  has_and_belongs_to_many :sites
  
end
