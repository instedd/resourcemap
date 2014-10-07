class DefaultFieldPermissionPolicy < ApplicationPolicy
  class Scope
    def resolve
      scope.where(memberships: {user_id: user}).includes(:membership)
    end
  end
end
