class NamePermission < ActiveRecord::Base
  include NameLocationPermissionActivityConcern
  belongs_to :membership
  validates :action, :inclusion => { :in => ["read", "update", "none"]}

  def set_access(action_value)
    self.action = action_value
    create_activity_if_permission_changed changes
    self.save!
  end

  def can_read?
    action == "read" || action == "update"
  end

  def can_update?
    action == "update"
  end

  def create_activity_if_permission_changed(changes)
    if activity_user && !changes.empty?
      data = {}
      data['changes'] = changes['action']
      data['user'] = membership.user.email
      Activity.create! item_type: 'name_permission', action: 'changed', collection_id: membership.collection_id, user_id: activity_user.id, data: data
    end
  end

end
