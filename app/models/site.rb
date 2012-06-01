class Site < ActiveRecord::Base
  include Activity::AwareConcern
  include Site::ActivityConcern
  include Site::GeomConcern
  include Site::TireConcern

  belongs_to :collection

  serialize :properties, Hash
  before_create :assign_id_with_prefix
  before_save :strongly_type_properties

  after_save :create_site_history
  before_destroy :update_site_history_expiration

  has_many :site_histories

  def create_site_history
    history = SiteHistory.create_from_site self
    self.site_histories.insert(history)
  end

  def update_site_history_expiration
    history = SiteHistory.first(:conditions => "site_id = #{self.id} AND valid_to IS NULL")
    history.valid_to = Time.now
    history.save
  end

  def strongly_type_properties
    fields = collection.fields.index_by(&:es_code)
    self.properties.keys.each do |key|
      field = fields[key]
      self.properties[key] = field.strongly_type(properties[key]) if field
    end
  end

  before_save :remove_nil_properties, :if => :properties
  def remove_nil_properties
    self.properties.reject! { |k, v| v.nil? }
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

  def assign_id_with_prefix
    self.id_with_prefix = generate_id_with_prefix if self.id_with_prefix.nil?
  end

  def generate_id_with_prefix
    site = Site.find_last_by_collection_id(self.collection_id)
    if site.nil?
      id_with_prefix = [Prefix.next.version,1]
    else
      id_with_prefix = site.get_id_with_prefix
      id_with_prefix[1].next!
    end
    id_with_prefix.join
  end

  def get_id_with_prefix
    self.id_with_prefix.split /(\d+)/
  end
end
