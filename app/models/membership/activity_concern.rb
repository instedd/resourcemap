module Membership::ActivityConcern
  extend ActiveSupport::Concern

  included do
    # The user that creates/makes changes to this object
    attr_accessor :activity_user

    after_create :create_activity_if_first_user
    after_create :create_activity_for_member
    after_destroy :create_activity_if_destroy_member
  end

  def create_activity_if_first_user
    memberships = collection.memberships
    if memberships.length == 1
      Activity.create! item_type: 'collection', action: 'created', collection_id: collection.id, user_id: memberships[0].user_id, 'data' => {'name' => collection.name}
    end
  end

  def create_activity_for_member
    if activity_user
      Activity.create! item_type: 'membership', action: 'created', collection_id: collection.id, user_id: activity_user.id, 'data' => {'user' => user.email}
    end
  end

  def create_activity_if_destroy_member
    if activity_user
      Activity.create! item_type: 'membership', action: 'deleted', collection_id: collection.id, user_id: activity_user.id, 'data' => {'user' => user.email}
    end
  end

  def create_activity_when_admin_permission_changes
    if activity_user
      Activity.create! item_type: 'admin_permission', action: 'changed', collection_id: collection.id, user_id: activity_user.id, 'data' => {'value' => admin, 'user' => user.email}
    end
  end

end
