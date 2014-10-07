class ImportJobPolicy < ApplicationPolicy
  class Scope
    def resolve
      scope.where(is_admin(t[:collection_id]))
    end
  end
end
