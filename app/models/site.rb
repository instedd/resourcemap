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

  def history_concern_foreign_key
    self.class.name.foreign_key
  end

  def extended_properties
    @extended_properties ||= Hash.new
  end

  def update_properties(site, user, props)
    props.each do |p|
      field = Field.find_by_code(p.values[0])
      site.properties[field.id.to_s] = p.values[1]
    end
    site.save!
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

end
