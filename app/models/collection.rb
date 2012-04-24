class Collection < ActiveRecord::Base
  include Collection::CsvConcern
  include Collection::GeomConcern
  include Collection::TireConcern

  validates_presence_of :name

  has_many :memberships
  has_many :layer_memberships
  has_many :users, through: :memberships
  has_many :sites, dependent: :delete_all
  has_many :root_sites, class_name: 'Site', conditions: {parent_id: nil}
  has_many :layers, dependent: :destroy
  has_many :fields

  def max_value_of_property(property)
    search = new_tire_search
    search.sort { by Site.encode_elastic_search_keyword(property), 'desc' }
    search.size 1
    search.perform.results.first['_source']['properties'][Site.encode_elastic_search_keyword(property)] rescue 0
  end

  def visible_fields_for(user)
    membership = user.membership_in self
    return [] unless membership

    target_fields = fields.includes(:layer)

    if membership.admin?
      target_fields = target_fields.all
    else
      lms = LayerMembership.where(user_id: user.id, collection_id: self.id).all.inject({}) do |hash, lm|
        hash[lm.layer_id] = lm
        hash
      end

      target_fields = target_fields.select { |f| lms[f.layer_id] && lms[f.layer_id].read }
    end

    layers = target_fields.map(&:layer).uniq.map do |layer|
      {
        id: layer.id,
        name: layer.name,
        ord: layer.ord,
      }
    end

    layers.each do |layer|
      layer[:fields] = target_fields.select { |field| field.layer_id == layer[:id] }
      layer[:fields].map! do |field|
        {
          id: field.id,
          name: field.name,
          code: field.code,
          kind: field.kind,
          config: field.config,
          writeable: !lms || lms[field.layer_id].write,
        }
      end
    end

    layers.sort! { |x, y| x[:ord] <=> y[:ord] }
    layers
  end

  # Returns the next ord value for a layer that is going to be created
  def next_layer_ord
    layer = layers.select('max(ord) as o').first
    layer ? layer['o'].to_i + 1 : 1
  end
end
