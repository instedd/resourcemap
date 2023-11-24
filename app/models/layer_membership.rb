class LayerMembership < ApplicationRecord

  include LayerMembershipActivityConcern
  belongs_to :membership
  belongs_to :layer

  after_save :touch_membership_lifespan
  after_destroy :touch_membership_lifespan

end
