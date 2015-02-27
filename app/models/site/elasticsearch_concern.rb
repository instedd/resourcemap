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
      if es_time_string.bytesize == 24
        # Optimization for when the string has 24 chars, which should
        # be something like this: 20140522T063835.000+0000
        # This is the format we store datetimes in Elasticsearch, so
        # the `else` part of the if shouldn't execute, but just in case...
        year = es_time_string[0, 4].to_i
        month = es_time_string[4, 2].to_i
        day = es_time_string[6, 2].to_i
        hour = es_time_string[9, 2].to_i
        minute = es_time_string[11, 2].to_i
        second = es_time_string[13, 2].to_i
        offset = es_time_string[19 .. -1].to_i
        time = Time.new(year, month, day, hour, minute, second, offset)
        ActiveSupport::TimeWithZone.new(time.utc, Time.zone)
      else
        Time.zone.parse(es_time_string)
      end
    end

    def iso_string_to_rfc822(iso_string)
      (DateTime.strptime iso_string, DateFormat).rfc822
    end

    def format_date(date)
      date.strftime DateFormat
    end
  end
end
