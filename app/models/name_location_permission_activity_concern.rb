module NameLocationPermissionActivityConcern
  extend ActiveSupport::Concern

  included do
    attr_accessor :activity_user
    before_update :create_activity_if_permission_changed
  end

  def create_activity_if_permission_changed
    if activity_user && !changes.empty?
      data = {}
      data['changes'] = changes['action']
      data['user'] = membership.user.email
      Activity.create! item_type: self.class.name.underscore, action: 'changed', collection_id: membership.collection_id, user_id: activity_user.id, data: data
    end
  end

end
