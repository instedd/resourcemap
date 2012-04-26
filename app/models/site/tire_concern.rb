module Site::TireConcern
  extend ActiveSupport::Concern

  DateFormat = "%Y%m%dT%H%M%S.%L%z"

  included do
    after_save :store_in_index, :unless => :group?
    after_destroy :remove_from_index, :unless => :group?
    after_find :decode_elastic_search_keywords, :unless => :group?, :if => :properties?

    delegate :index_name, :index, to: :collection
  end

  def store_in_index(options = {})
    hash = {
      id: id,
      name: name,
      type: :site,
      properties: self.class.encode_elastic_search_keywords(properties),
      created_at: created_at.strftime(DateFormat),
      updated_at: updated_at.strftime(DateFormat),
    }
    hash[:location] = {lat: lat.to_f, lon: lng.to_f} if lat? && lng?
    hash[:parent_ids] = hierarchy.split(',').map(&:to_i) if hierarchy?
    result = index.store hash

    if result['error']
      raise "Can't store site in index: #{result['error']}"
    end

    index.refresh unless options[:refresh] == false
  end

  def remove_from_index
    index.remove id: id, type: :site
    index.refresh
  end

  module ClassMethods
    def parse_date(date)
      DateTime.strptime date, DateFormat
    end

    def format_date(date)
      date.strftime DateFormat
    end

    def encode_elastic_search_keywords(hash)
      Hash[
        hash.map do |key, value|
          [encode_elastic_search_keyword(key), value]
        end
      ]
    end

    def decode_elastic_search_keywords(hash)
      Hash[
        hash.map do |key, value|
          [decode_elastic_search_keyword(key), value]
        end
      ]
    end

    def encode_elastic_search_keyword(key)
      key = "@#{key}" unless key.to_s[0] == '@'
      key
    end

    def decode_elastic_search_keyword(key)
      key = key.to_s[1 .. -1] if key.to_s[0] == '@'
      key
    end
  end

  private

  def decode_elastic_search_keywords
    self.properties = self.class.decode_elastic_search_keywords(properties)
  end
end
