class LayerMembership < ActiveRecord::Base

  include LayerMembershipActivityConcern
  belongs_to :membership
  belongs_to :layer

end
