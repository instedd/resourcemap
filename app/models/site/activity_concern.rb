module Site::ActivityConcern
  extend ActiveSupport::Concern

  included do
    after_create :create_activity, :unless => :mute_activities
  end

  def create_activity
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
end
