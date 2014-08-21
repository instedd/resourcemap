class DefaultFieldPermission < ActiveRecord::Base
  self.abstract_class = true

  include NameLocationPermissionActivityConcern
  belongs_to :membership
  validates :action, :inclusion => { :in => ["read", "update", "none"]}

  def set_access(action_value)
    self.action = action_value
    self.save!
  end

  def can_read?
    action == "read" || action == "update"
  end

  def can_update?
    action == "update"
  end
end
