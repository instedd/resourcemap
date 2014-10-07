class UserSnapshotPolicy < ApplicationPolicy
  class Scope
    def resolve
      scope.where(t[:user_id].eq(user.id))
    end
  end
end
