module Site::ElasticsearchConcern
  extend ActiveSupport::Concern

  DateFormat = "%Y%m%dT%H%M%S.%L%z"

  included do
    after_save :store_in_index
    after_destroy :remove_from_index
    define_model_callbacks :index
    delegate :index_name, to: :collection
  end

  def store_in_index(options = {})
    run_callbacks :index do
      Site::IndexUtils.store self, id, index_name, options
    end
  end

  def to_elastic_search
    Site::IndexUtils.to_elastic_search(self, id)
  end

  def from_index
    search = collection.new_search
    search.id id
    search.results.first
  end

  def remove_from_index
    client = Elasticsearch::Client.new
    client.delete index: index_name, id: id, type: 'site'
    client.indices.refresh index: index_name
  end

  module ClassMethods
    def parse_time(es_time_string)
      Time.zone.parse(es_time_string)
    end

    def iso_string_to_rfc822(iso_string)
      (DateTime.strptime iso_string, DateFormat).rfc822
    end

    def format_date(date)
      date.strftime DateFormat
    end
  end
end
