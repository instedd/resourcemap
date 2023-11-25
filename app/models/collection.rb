class Collection < ApplicationRecord
  include Collection::CsvConcern
  include Collection::GeomConcern
  include Collection::ElasticsearchConcern
  include Collection::PluginsConcern
  include Collection::ImportLayersSchemaConcern

  mount_uploader :logo, LogoUploader
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h

  validates_presence_of :name, :message => N_("can't be blank")
  validates_presence_of :icon

  has_many :memberships, dependent: :delete_all
  has_many :users, through: :memberships
  has_many :sites, dependent: :delete_all
  has_many :layers, -> { order('layers.ord')}, dependent: :delete_all
  has_many :fields, -> { order('ord')}, dependent: :delete_all
  has_many :thresholds, dependent: :delete_all
  has_many :reminders, dependent: :delete_all
  has_many :share_channels, dependent: :delete_all
  has_many :channels, :through => :share_channels
  has_many :activities, dependent: :delete_all
  has_many :snapshots, dependent: :destroy
  has_many :user_snapshots, dependent: :delete_all
  has_many :site_histories, dependent: :delete_all
  has_many :layer_histories, dependent: :delete_all
  has_many :field_histories, dependent: :delete_all
  has_many :messages, dependent: :delete_all
  OPERATOR = {">" => "gt", "<" => "lt", ">=" => "gte", "<=" => "lte", "=>" => "gte", "=<" => "lte", "=" => "eq"}

  after_save do
    logo.recreate_versions!(:grayscale) if logo.present? and crop_x.present?
  end

  after_save :touch_lifespan
  after_destroy :touch_lifespan

  def max_value_of_property(es_code)
    client = Elasticsearch::Client.new
    results = client.search index: index_name, type: 'site', body: {
      sort: {"properties.#{es_code}" => 'desc'},
      size: 2000,
    }
    results["hits"]["hits"].first['_source']['properties'][es_code] rescue 0
  end

  def membership_for(user)
    membership = memberships.where(user_id: user.id).first
    if user.is_guest or !membership
      if (self.anonymous_name_permission == 'read')
        # Dummy membership with read permission
        m = Membership.new collection: self, user: user, admin: false
        m.create_default_associations
        m
      end
    else
      membership
    end
  end

  def public?
    anonymous_name_permission == "read" && anonymous_location_permission == "read"
  end

  def snapshot_for(user)
    snapshots.where(user_snapshots: {user_id: user}).includes(:user_snapshots).first
  end

  def writable_fields_for(user)
    membership = user.membership_in self
    return [] unless membership

    target_fields = fields.includes(:layer)

    if membership.admin?
      target_fields = target_fields
    else
      lms = LayerMembership.where(membership_id: membership.id).inject({}) do |hash, lm|
        hash[lm.layer_id] = lm
        hash
      end

      target_fields = target_fields.select {|f| lms[f.layer_id] && lms[f.layer_id].write}

    end
    target_fields
  end

  def visible_fields_for(user, options = {})
    current_ability = Ability.new(user)

    if options[:snapshot_id]
      date = Snapshot.where(id: options[:snapshot_id]).first.date
      visible_layers = layer_histories.accessible_by(current_ability).at_date(date).includes(:layer).map(&:layer).uniq
    else
      visible_layers = layers.accessible_by(current_ability).distinct
    end

    fields_by_layer_id = Field.where(layer_id: visible_layers.map(&:id)).load.group_by(&:layer_id)

    visible_layers.map do |layer|
      fields = fields_by_layer_id[layer.id]
      if fields
        fields.each do |field|
          field.layer = layer
        end
      end
      fields || []
    end.flatten
  end

  def visible_layers_for(user, options = {})
    current_ability = Ability.new(user)

    if options[:snapshot_id]
      date = Snapshot.where(id: options[:snapshot_id]).first.date
      visible_layers = layer_histories.accessible_by(current_ability).at_date(date).distinct
    else
      visible_layers = layers.accessible_by(current_ability).includes(:fields).distinct
    end

    json_layers = []

    visible_layers.each do |layer|
      json_layer = {}
      json_layer[:id] = layer.id
      json_layer[:name] = layer.name
      json_layer[:ord] = layer.ord
      json_layer[:fields] = []

      layer.fields.each do |field|
        json_field = {}
        json_field[:id] = field.es_code
        json_field[:name] = field.name
        json_field[:code] = field.code
        json_field[:kind] = field.kind
        json_field[:config] = field.config
        json_field[:ord] = field.ord
        json_field[:writeable] = current_ability.can?(:update_site_property, field, nil)

        json_layer[:fields] << json_field
      end
      json_layers << json_layer
    end
    json_layers.sort! { |x, y| x[:ord] <=> y[:ord] }

    json_layers
  end

  # Returns the next ord value for a layer that is going to be created
  def next_layer_ord
    layer = layers.select('max(ord) as o').first
    layer ? layer['o'].to_i + 1 : 1
  end

  def delete_sites_and_activities
    ActiveRecord::Base.transaction do
      Activity.where(collection_id: id).delete_all
      Site.where(collection_id: id).delete_all
      recreate_index
    end
  end

  def thresholds_test(site)
    catch(:threshold) {
      thresholds.each do |threshold|
        threshold.test site.properties if threshold.is_all_site || threshold.sites.any? { |selected| selected["id"] == site.id }
      end
      nil
    }
  end

  def query_sites(option)
    operator = operator_parser option[:operator]
    field = Field.find_by_code option[:code]

    search = self.new_search
    search.use_codes_instead_of_es_codes

    search.send operator, field, option[:value]
    results = search.results
    response_prepare(option[:code], field.id, results)
  end

  def response_prepare(field_code, field_id, results)
    array_result = []
    results.each do |r|
      array_result.push "#{r["_source"]["name"]}=#{r["_source"]["properties"][field_id.to_s]}"
    end
    response_sms = (array_result.empty?)? "There is no site matched" : array_result.join(", ")
    result = "[\"#{field_code}\"] in #{response_sms}"
    result
  end

  def operator_parser(op)
    OPERATOR[op]
  end

  def active_gateway
    self.channels.each do |channel|
      return channel if channel.client_connected && channel.is_enable && !channel.share_channels.find_by_collection_id(id).nil?
    end
    nil
  end

  def get_user_owner
    memberships.find_by_admin(true).user
  end

  def get_gateway_under_user_owner
    get_user_owner.get_gateway
  end

  def register_gateways_under_user_owner(owner_user)
    self.channels = owner_user.channels.where(is_enable: true)
  end

  # Returns a dictionary of :code => :es_code of all the fields in the collection
  def es_codes_by_field_code
    self.fields.inject({}) do |dict, field|
      dict[field.code] = field.es_code
      dict
    end
  end

  def new_site_properties
    self.fields.each_with_object({}) do |field, hash|
      value = field.default_value_for_create(self)
      hash[field.es_code] = value if value
    end
  end

  def layers_to_json(at_present, user)
    if at_present
      layers.includes(:fields).select{|l| user.can?(:read, l)}.as_json(include: :fields)
    else
      current_user_snapshot = UserSnapshot.for(user, self)
      layer_histories.at_date(current_user_snapshot.snapshot.date)
        .includes(:field_histories)
        .select{|l| user.can?(:read, l)}
        .as_json(include: :field_histories)
    end
  end

  private

  def touch_lifespan
    Telemetry::Lifespan.touch_collection self
  end
end
