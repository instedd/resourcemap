module Site::TireConcern
  extend ActiveSupport::Concern

  DateFormat = "%Y%m%dT%H%M%S.%L%z"

  included do
    after_save :store_in_index
    after_destroy :remove_from_index

    delegate :index_name, :index, to: :collection
  end

  def store_in_index(options = {})
    Site::IndexUtils.store self, id, index, options
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

    def parse_date(date)
      DateTime.strptime date, DateFormat
    end

    def format_date(date)
      date.strftime DateFormat
    end
  end
end
