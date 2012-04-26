module Site::ActivityConcern
  extend ActiveSupport::Concern

  included do
    after_create :create_created_activity, :unless => :mute_activities
    after_update :create_updated_activity, :unless => :mute_activities
    after_destroy :create_deleted_activity, :unless => :mute_activities
  end

  def create_created_activity
    site_data = {name: name}
    site_data[:lat] = lat if lat
    site_data[:lng] = lng if lng
    if group?
      site_data[:location_mode] = location_mode
    else
      site_data[:properties] = properties if properties.present?
    end
    kind = group? ? 'group_created' : 'site_created'
    Activity.create! kind: kind, collection_id: collection.id, site_id: id, user_id: user.id, data: site_data
  end

  def create_updated_activity
    site_changes = changes.except 'updated_at', 'min_lat', 'max_lat', 'min_lng', 'max_lng', 'min_zoom', 'max_zoom'

    # If either lat or lng change we want to singal a change in both, as in "location changed" and
    # we can show what the location was before and was it now without consulting the site's properties
    site_changes['lat'] = [lat, lat] if !site_changes['lat'] && site_changes['lng']
    site_changes['lng'] = [lng, lng] if site_changes['lat'] && !site_changes['lng']

    if site_changes.present?
      Activity.create! kind: (group? ? 'group_changed' : 'site_changed'), collection_id: collection.id, user_id: user.id, site_id: id, data: {name: name, changes: site_changes}
    end
  end

  def create_deleted_activity
    Activity.create! kind: (group? ? 'group_deleted' : 'site_deleted'), collection_id: collection.id, user_id: user.id, site_id: id, data: {name: name}
  end
end
