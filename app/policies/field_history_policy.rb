class FieldHistoryPolicy < ApplicationPolicy
  def destroy?
    select_bool(is_admin(record.collection_id))
  end
end
