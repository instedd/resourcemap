class ActivityPolicy < ApplicationPolicy
  class Scope
    def resolve
      scope.where(is_member(t[:collection_id]))
    end
  end
end
