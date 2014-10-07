module PolicyHelper
  def is_admin(collection_id)
    m = Arel::Table.new(Membership.table_name)
    m.table_alias = "membership_#{rand(99999)}"
    m.where(m[:user_id].eq(user.id)
            .and m[:collection_id].eq(collection_id)
            .and m[:admin].eq(true)).project(Arel.star).exists
  end

  def is_member(collection_id)
    m = Arel::Table.new(Membership.table_name)
    m.table_alias = "membership_#{rand(99999)}"
    m.where(m[:user_id].eq(user.id).and(m[:collection_id].eq(collection_id))).project(Arel.star).exists
  end

  def select_bool(arel_query)
    ActiveRecord::Base.connection.select_value("SELECT #{arel_query.to_sql}") == 1
  end
end
