module Field::TireConcern
  extend ActiveSupport::Concern

  def index_mapping
    case kind
    when 'numeric'
      { type: :long }
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
      where(:id => es_code.to_i)
    end
  end
end
