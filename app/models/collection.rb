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

    target_fields = fields

    unless membership.admin?
      lms = LayerMembership.where(user_id: user.id, collection_id: self.id).all.inject({}) do |hash, lm|
        hash[lm.layer_id] = lm
        hash
      end

      target_fields = fields.select { |f| lms[f.layer_id] && lms[f.layer_id].read }
    end

    target_fields.map do |f|
      {
        id: f.id,
        name: f.name,
        code: f.code,
        kind: f.kind,
        config: f.config,
        writeable: !lms || lms[f.layer_id].write,
      }
    end
  end

  # Searches value codes from their labels on this collections' fields,
  # or in the given fields. Returns an array of the matching codes.
  def search_value_codes(text, fields_to_search = nil)
    fields_to_search ||= fields.all.select &:select_kind?

    codes = []
    regex = /#{text}/i
    fields_to_search.each do |field|
      field.config['options'].each do |option|
        if option['label'] =~ regex
          codes << option['code']
        end
      end
    end
    codes
  end
end
