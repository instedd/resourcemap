class SitePolicy < ApplicationPolicy
  class Scope
    def resolve
      scope.where(is_member(t[:collection_id]))
    end
  end

  def destroy?
    select_bool(is_admin(record.collection_id))
  end
end
