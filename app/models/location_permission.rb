class LocationPermission < ActiveRecord::Base
  belongs_to :membership
  validates :action, :inclusion => { :in => ["read", "update", "none"]}

  def can_read?
    action == "read" || action == "update"
  end

  def can_update?
    action == "update"
  end

end
