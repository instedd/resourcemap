class LayerPolicy < ApplicationPolicy
  class Scope
    def can_read_layer(layer_id)
      lm = LayerMembership.arel_table
      LayerMembership.where(layer_id: layer_id).where(
        lm[:read].eq(true).or(lm[:write].eq(true))
      ).joins(:membership).where(memberships: { user_id: user }).exists
    end

    def resolve
      if user.is_guest
        scope.where(t[:anonymous_user_permission].eq("read"))
      else
        scope.where(is_admin(t[:collection_id]) .or can_read_layer(t[:id]))
      end
    end
  end

  def destroy?
    select_bool(is_admin(record.collection_id))
  end
end
