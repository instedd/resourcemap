module Membership::ActivityConcern
  extend ActiveSupport::Concern

  included do
    after_create :create_activity_if_first_user
    after_create :create_activity_for_member
    after_destroy :create_activity_if_destroy_member
  end

  def create_activity_if_first_user
    memberships = collection.memberships.all
    if memberships.length == 1
      Activity.create! item_type: 'collection', action: 'created', collection_id: collection.id, user_id: memberships[0].user_id, 'data' => {'name' => collection.name}
    end
  end

  def create_activity_if_destroy_member
    Activity.create! item_type: 'membership', action: 'deleted', collection_id: collection.id, user_id: user_id, 'data' => {'email' => user.email}
  end

end
