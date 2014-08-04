module Site::ActivityConcern
  extend ActiveSupport::Concern

  class DefaultStrategy
    def self.create_activity(item_type, action, collection_id, site_id, user_id, data)
      Activity.create! item_type: item_type, action: action, collection_id: collection_id, site_id: site_id, user_id: user_id, data: data
    end
  end

  class BulkStrategy
    def initialize
      @column_names = [:item_type, :action, :collection_id, :site_id, :user_id, :data]
      @activities = []
    end

    def create_activity(item_type, action, collection_id, site_id, user_id, data)
      @activities << [item_type, action, collection_id, site_id, user_id, data]
      flush if @activities.length >= 1000
    end

    def flush
      unless @activities.empty?
        Activity.import @column_names, @activities, validate: false
        @activities.clear
      end
    end
  end

  def self.strategy
    Thread.current[:site_activity_concern] || DefaultStrategy
  end

  def self.strategy=(strategy)
    Thread.current[:site_activity_concern] = strategy
  end

  def self.bulk
    self.strategy = BulkStrategy.new
    yield
  ensure
    self.strategy.flush
    self.strategy = nil
  end

  included do
    after_create :create_created_activity, :unless => :mute_activities
    before_update :record_name_was, :unless => :mute_activities
    after_update :create_updated_activity, :unless => :mute_activities
    after_destroy :create_deleted_activity, :unless => :mute_activities, :if => :user
  end

  def create_created_activity
    site_data = {'name' => @name_was || name}
    site_data['lat'] = lat if lat
    site_data['lng'] = lng if lng
    site_data['properties'] = properties if properties.present?

    Site::ActivityConcern.strategy.create_activity 'site', 'created', collection.id, id, user.id, site_data
  end

  def record_name_was
    @name_was = name_was
  end

  def create_updated_activity
    site_changes = changes.except('updated_at', 'min_lat', 'max_lat', 'min_lng', 'max_lng', 'min_zoom', 'max_zoom', 'version').to_hash

    # If either lat or lng change we want to singal a change in both, as in "location changed" and
    # we can show what the location was before and was it now without consulting the site's properties
    lat_changed = site_changes['lat'] && (changes['lat'][0].nil? || changes['lat'][1].nil? || (changes['lat'][0] - changes['lat'][1]).abs >= 1e-04)
    lng_changed = site_changes['lng'] && (changes['lng'][0].nil? || changes['lng'][1].nil? || (changes['lng'][0] - changes['lng'][1]).abs >= 1e-04)

    if(lat_changed && !site_changes['lng'])
      site_changes['lng'] = [lng, lng]
    end

    if(lng_changed && !site_changes['lat'])
      site_changes['lat'] = [lat, lat]
    end

    if !lat_changed && !lng_changed
      site_changes.delete 'lat'
      site_changes.delete 'lng'
    end

    if site_changes.present?
      Site::ActivityConcern.strategy.create_activity 'site', 'changed', collection.id, id, user.id, {'name' => @name_was || name, 'changes' => site_changes}
    end
  end

  def create_deleted_activity
    Site::ActivityConcern.strategy.create_activity 'site', 'deleted', collection.id, id, user.id, {'name' => name}
  end
end
