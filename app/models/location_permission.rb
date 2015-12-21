class LocationPermission < DefaultFieldPermission
  after_save :touch_membership_lifespan
  after_destroy :touch_membership_lifespan
end
