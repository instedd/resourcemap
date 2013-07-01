class Site < ActiveRecord::Base
  include Activity::AwareConcern
  include Site::ActivityConcern
  include Site::CleanupConcern
  include Site::GeomConcern
  include Site::PrefixConcern
  include Site::TireConcern
  include HistoryConcern

  belongs_to :collection
  validates_presence_of :name

  serialize :properties, Hash
  before_validation :convert_codes_to_es_codes
  validate :valid_properties


  attr_accessor :use_codes_instead_of_es_codes
  attr_accessor :from_import_wizard

  def history_concern_foreign_key
    self.class.name.foreign_key
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

  private

  def convert_codes_to_es_codes
    if use_codes_instead_of_es_codes

      fields_by_code = collection.fields.index_by(&:code)
      fields_by_es_code = collection.fields.index_by(&:es_code)

      properties_by_es_code = {}
      properties.each do |code, value|
        field = fields_by_code[code] || fields_by_es_code[code]
        raise "Invalid field identifier: There is not a field with code = '#{code}' or es_code = '#{code}' in collection number #{collection_id}." unless field
       properties_by_es_code["#{field.es_code}"] = value
      end

     self.properties = properties_by_es_code
    end
  end

  def valid_properties
    fields = collection.fields.index_by(&:es_code)

    if new_record?
      fields.each do |es_code, field|
        if properties[field.es_code].blank?
          value = field.default_value_for_create(collection)
          properties[field.es_code] = value if value
        end
      end
    end

    validated_properties = {}
    properties.each do |es_code, value|
      field = fields[es_code]
      raise "Invalid field identifier: There is not a field with es_code = '#{es_code}' in collection number #{collection_id}." unless field
      begin
        validated_value = field.apply_format_save_validation(value, use_codes_instead_of_es_codes, collection, self)
        validated_properties["#{field.es_code}"] = validated_value
      rescue => ex
        errors.add(:properties, {field.es_code => ex.message})
      end
    end

    self.use_codes_instead_of_es_codes = false # Clean the value for next validation calls over the same site
    self.properties = validated_properties
  end

end
