class FieldPolicy < ApplicationPolicy
  class Scope
    def resolve
      scope.where(is_member(t[:collection_id]))
    end
  end

  def destroy?
    select_bool(is_admin(record.collection_id))
  end

  def update_site_property?
    return false if user.is_guest
    membership = user.memberships.where(collection_id: record.collection_id).includes(:layer_memberships).first
    return false unless membership
    return true if membership.admin?

    layer_membership = membership.layer_memberships.find { |lm| lm.layer_id == record.layer_id }
    layer_membership && layer_membership.write
  end
end

Field.subclasses.each do |field_class|
  class_eval %(class #{field_class.name}Policy < FieldPolicy; end)
end
