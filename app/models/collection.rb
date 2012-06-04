class Collection < ActiveRecord::Base
  include Collection::CsvConcern
  include Collection::GeomConcern
  include Collection::TireConcern

  validates_presence_of :name

  has_many :memberships, :dependent => :destroy
  has_many :layer_memberships
  has_many :users, through: :memberships
  has_many :sites, dependent: :delete_all
  has_many :layers, order: 'ord', dependent: :destroy
  has_many :fields, order: 'ord'
  has_many :thresholds

  OPERATOR = {">" => "gt", "<" => "lt", ">=" => "gte", "<=" => "lte", "=>" => "gte", "=<" => "lte", "=" => "eq"}

  def max_value_of_property(es_code)
    search = new_tire_search
    search.sort { by es_code, 'desc' }
    search.size 2000
    results = search.perform.results
    results.first['_source']['properties'][es_code] rescue 0
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
          ord: field.ord,
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

  def thresholds_test(properties)
    catch(:threshold) {
      thresholds.each do |threshold|
        threshold.test properties
      end
      false
    }
  end

  def query_sites(option)
    operator = operator_parser option[:operator]
    field = Field.find_by_code option[:code]

    search = self.new_search
    search.use_codes_instead_of_es_codes
     
    search.send operator , option[:code], option[:value]
    results = search.results
    response_prepare(option[:code], field.id, results)
  end

  def response_prepare(field_code, field_id, results)
    array_result = []
    results.each do |r|
      array_result.push r["_source"]["name"]  # get site name
      array_result.push r["_source"]["properties"][field_id.to_s] # get properties value
    end
    response_sms = (array_result.empty?)? "There is no site matched" : array_result.join(", ")
    result = "[\"#{field_code}\"] in #{response_sms}"
    result
  end

  def operator_parser(op)
    OPERATOR[op]
  end
end
