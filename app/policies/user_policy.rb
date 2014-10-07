class UserPolicy < ApplicationPolicy
  class Scope
    def resolve
      scope.scoped
    end
  end
end
