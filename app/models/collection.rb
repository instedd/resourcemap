class Collection < ActiveRecord::Base
  include Collection::CsvConcern
  include Collection::GeomConcern
  include Collection::TireConcern
  include Collection::PluginsConcern
  include Collection::ImportLayersSchemaConcern

  mount_uploader :logo, LogoUploader
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h

  validates_presence_of :name
  validates_presence_of :icon

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :sites, dependent: :delete_all
  has_many :layers, order: 'ord', dependent: :destroy
  has_many :fields, order: 'ord'
  has_many :thresholds, dependent: :destroy
  has_many :reminders, dependent: :destroy
  has_many :share_channels, dependent: :destroy
  has_many :channels, :through => :share_channels
  has_many :activities, dependent: :destroy
  has_many :snapshots, dependent: :destroy
  has_many :user_snapshots, :through => :snapshots
  has_many :site_histories, dependent: :destroy
  has_many :layer_histories, dependent: :destroy
  has_many :field_histories, dependent: :destroy
  has_many :messages, dependent: :destroy
  OPERATOR = {">" => "gt", "<" => "lt", ">=" => "gte", "<=" => "lte", "=>" => "gte", "=<" => "lte", "=" => "eq"}

  def max_value_of_property(es_code)
    search = new_tire_search
    search.sort { by es_code, 'desc' }
    search.size 2000
    results = search.perform.results
    results.first['_source']['properties'][es_code] rescue 0
  end

  def membership_for(user)
    if user.is_guest && self.public
      # Dummy membership with read permission
      m = Membership.new collection: self, user: user, admin: false
      m.create_default_associations
      m
    else
      memberships.where(user_id: user.id).first
    end
  end

  def snapshot_for(user)
    user_snapshots.where(user_id: user.id).first.try(:snapshot)
  end

  def writable_fields_for(user)
    membership = user.membership_in self
    return [] unless membership

    target_fields = fields.includes(:layer)

    if membership.admin?
      target_fields = target_fields.all
    else
      lms = LayerMembership.where(membership_id: membership.id).all.inject({}) do |hash, lm|
        hash[lm.layer_id] = lm
        hash
      end

      target_fields = target_fields.select {|f| lms[f.layer_id] && lms[f.layer_id].write}

    end
    target_fields
  end

  def visible_fields_for(user, options)
    current_ability = Ability.new(user)

    if options[:snapshot_id]
      date = Snapshot.where(id: options[:snapshot_id]).first.date
      visible_layers = layer_histories.accessible_by(current_ability).at_date(date).includes(:layer).map(&:layer)
    else
      visible_layers = layers.accessible_by(current_ability).all
    end

    fields_by_layer_id = Field.where(layer_id: visible_layers.map(&:id)).all.group_by(&:layer_id)

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
      visible_layers = layer_histories.accessible_by(current_ability).at_date(date)
    else
      visible_layers = layers.accessible_by(current_ability).includes(:fields)
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
    self.channels = owner_user.channels.find_all_by_is_enable true
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
end
