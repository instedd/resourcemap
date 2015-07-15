module Field::ElasticsearchConcern
  extend ActiveSupport::Concern

  def index_mapping
    case
    when kind == 'yes_no'
      { type: :boolean }
    when stored_as_number?
      if kind == 'numeric' && allow_decimals?
        { type: :float }
      else
        { type: :long }
      end
    when stored_as_date?
      { type: :date }
    when kind == 'text'
      {
        type: :multi_field,
        fields: {
          es_code => { type: :string, index: :not_analyzed },
          "#{es_code}.downcase" => { type: :string, path: :just_name, index: :analyzed, analyzer: :downcase },
        },
      }
    else
      { type: :string, index: :not_analyzed }
    end
  end

  # Returns the code to store this field in Elastic Search
  def es_code
    id.to_s
  end

  def es_property_path
    "property.#{es_code}"
  end

  def search_fields_mapping(mapping)
    if kind == 'hierarchy'
      mapping["#{es_code}_path"] = { type: :string, index: :not_analyzed }
    end
  end

  def search_properties(hash, value)
    if kind == 'hierarchy'
      begin
        hash["#{es_code}_path"] = self.ascendants_of_in_hierarchy(value).map { |n| n['id'] }
      rescue
        # if hierarchy node does not exist, then we need to skip this
      end
    end
  end

  module ClassMethods
    def where_es_code_is(es_code)
      where(:id => es_code.to_i).first
    end
  end
end
