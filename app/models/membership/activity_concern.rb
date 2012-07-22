module Membership::ActivityConcern
  extend ActiveSupport::Concern

  included do
    after_create :create_activity_if_first_user
  end

  def create_activity_if_first_user
    memberships = collection.memberships.all
    if memberships.length == 1
      Activity.create! kind: 'collection_created', collection_id: collection.id, user_id: memberships[0].user_id, 'data' => {'name' => collection.name}
    end
  end
end
