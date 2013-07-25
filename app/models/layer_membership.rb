class LayerMembership < ActiveRecord::Base
  belongs_to :collection
  belongs_to :user
  belongs_to :layer
end
