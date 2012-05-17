class Reminder < ActiveRecord::Base
  belongs_to :repeat
  belongs_to :collection
end
