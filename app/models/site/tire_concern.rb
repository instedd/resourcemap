module Site::TireConcern
  extend ActiveSupport::Concern

  DateFormat = "%Y%m%dT%H%M%S.%L%z"

  included do
    after_save :store_in_index
    after_destroy :remove_from_index
    define_model_callbacks :index
    delegate :index_name, :index, to: :collection
  end

  def store_in_index(options = {})
    run_callbacks :index do
      Site::IndexUtils.store self, id, index, options
    end
  end

  def from_index
    search = collection.new_search
    search.id id
    search.results.first
  end

  def remove_from_index
    index.remove id: id, type: :site
    index.refresh
  end

  module ClassMethods
    def parse_time(es_time_string)
      Time.zone.parse(es_time_string)
    end

    def iso_string_to_mdy(iso_string)
      Time.iso8601(iso_string).strftime("%m/%d/%Y")
    end

    def iso_string_to_rfc822(iso_string)
      (DateTime.strptime iso_string, DateFormat).rfc822
    end

    def format_date(date)
      date.strftime DateFormat
    end
  end
end
