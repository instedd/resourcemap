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
        type: :string, index: :not_analyzed,
        fields: {
          downcase: { type: :string, index: :analyzed, analyzer: :downcase },
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

  module ClassMethods
    def where_es_code_is(es_code)
      where(:id => es_code.to_i).first
    end
  end
end
