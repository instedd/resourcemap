class CollectionPolicy < ApplicationPolicy
  class Scope
    def resolve
      scope.where(is_member(t[:id]))
    end
  end

  def destroy?
    select_bool(is_admin(record.id))
  end
end
