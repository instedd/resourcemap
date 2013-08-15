class LayerMembership < ActiveRecord::Base
  belongs_to :membership
  belongs_to :layer
end
