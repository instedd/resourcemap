class LayerMembershipPolicy < ApplicationPolicy
  class Scope
    def resolve
      # scope.where(memberships: {collection_id: member_collections}).includes(:membership)
      memberships = Membership.where(is_admin(Membership.arel_table[:collection_id]))
      scope.where(membership_id: memberships)
    end
  end
end


