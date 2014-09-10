class Site < ActiveRecord::Base
  include Activity::AwareConcern
  include Site::ActivityConcern
  include Site::CleanupConcern
  include Site::GeomConcern
  include Site::PrefixConcern
  include Site::ElasticsearchConcern
  include HistoryConcern

  belongs_to :collection
  validates_presence_of :name

  serialize :properties, JSON
  validate :valid_properties
  after_validation :standardize_properties

  before_create :set_version
  before_update :set_version

  def properties
    self["properties"] ||= {}
  end

  attr_accessor :from_import_wizard

  def history_concern_foreign_key
    self.class.name.foreign_key
  end

  def set_version
    return if !self.respond_to?(:version)
    self.version = self.version + 1
  end

  def extended_properties
    @extended_properties ||= Hash.new
  end

  def human_properties
    fields = collection.fields.index_by(&:es_code)

    props = {}
    properties.each do |key, value|
      field = fields[key]
      if field
        props[field.name] = field.human_value value
      else
        props[key] = value
      end
    end
    props
  end

  def self.get_id_and_name sites
    sites = Site.select("id, name").find(sites)
    sites_with_id_and_name = []
    sites.each do |site|
      site_with_id_and_name = {
        "id" => site.id,
        "name" => site.name
      }
      sites_with_id_and_name.push site_with_id_and_name
    end
    sites_with_id_and_name
  end

  def self.create_or_update_from_hash! hash
    site = Site.where(:id => hash["site_id"]).first_or_initialize
    site.prepare_attributes_from_hash!(hash)
    site.save ? site : nil
  end

  def prepare_attributes_from_hash!(hash)
    self.collection_id = hash["collection_id"]
    self.name = hash["name"]
    self.lat = hash["lat"]
    self.lng = hash["lng"]
    self.user = hash["current_user"]
    properties = {}
    hash["existing_fields"].each_value do |field|
      properties[field["field_id"].to_s] = field["value"]
    end
    self.properties = properties
  end

  def assign_default_values_for_create
    fields = collection.fields.index_by(&:es_code)

    fields.each do |es_code, field|
      if properties[field.es_code].blank?
        value = field.default_value_for_create(collection)
        properties[field.es_code] = value if value
      end
    end
    self
  end

  def assign_default_values_for_update
    fields = collection.fields.index_by(&:es_code)

    fields.each do |es_code, field|
      value = field.default_value_for_update
      properties[field.es_code] = value unless value.nil?
    end
    self
  end

  def update_single_property!(es_code, value)
    field = collection.fields.where_es_code_is es_code
    properties_will_change!
    assign_default_values_for_update
    properties[es_code] = field.decode_from_ui(value)
    self.valid? && self.save!
  end

  def validate_and_process_parameters(site_params, user)
    user_membership = user.membership_in(collection)

    if site_params.has_key?("name")
      user.authorize! :update_name, user_membership, "Not authorized to update site name"
      self.name = site_params["name"]
    end

    if site_params.has_key?("lng")
      user.authorize! :update_location, user_membership, "Not authorized to update site location"
      self.lng = site_params["lng"]
    end

    if site_params.has_key?("lat")
      user.authorize! :update_location, user_membership, "Not authorized to update site location"
      self.lat = site_params["lat"]
    end

    if site_params.has_key?("properties")
      fields = collection.fields.index_by(&:es_code)

      site_params["properties"].each_pair do |es_code, value|

        #Next if there is no changes in the property
        next if value == self.properties[es_code]

        field = fields[es_code]
        user.authorize! :update_site_property, field, "Not authorized to update site property with code #{es_code}"
        self.properties[es_code] = field.decode_from_ui(value)
      end
    end

    # after, so if the user update the whole site
    # the auto_reset is reseted
    if self.changed?
      self.assign_default_values_for_update
    end
  end

  def decode_properties_from_ui(parameters)
    fields = collection.fields.index_by(&:es_code)
    decoded_properties = {}
    site_properties = parameters.delete "properties"
    site_properties ||= {}
    site_properties.each_pair do |es_code, value|
      decoded_properties[es_code] = fields[es_code].decode_from_ui(value)
    end

    parameters["properties"] = decoded_properties
    parameters
  end


  private

  def standardize_properties
    fields = collection.fields.index_by(&:es_code)

    standardized_properties = {}
    properties.each do |es_code, value|
      field = fields[es_code]
      if field
        standardized_properties[es_code] = field.standardize(value)
      end
    end
    self.properties = standardized_properties
  end

  def valid_properties
    fields = collection.fields.each(&:cache_for_read).index_by(&:es_code)

    properties.each do |es_code, value|
      field = fields[es_code]
      if field
        begin
          field.valid_value?(value, self.id)
        rescue => ex
          errors.add(:properties, {field.es_code => ex.message})
        end
      end
    end
  end
end
