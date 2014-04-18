class LocationPermission < ActiveRecord::Base
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
    data = changes
    Activity.create! item_type: 'location_permission', action: 'changed', collection_id: membership.collection_id, user_id: membership.user_id, data: data
  end


end
