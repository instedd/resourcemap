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

  def elastic_search_code
    Site.encode_elastic_search_keyword code
  end
end
