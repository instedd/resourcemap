module Site::TireConcern
  extend ActiveSupport::Concern

  DateFormat = "%Y%m%dT%H%M%S.%L%z"

  included do
    after_save :store_in_index, :unless => :group?
    after_destroy :remove_from_index, :unless => :group?

    delegate :index_name, :index, to: :collection
  end

  def store_in_index
    hash = {
      id: id,
      type: :site,
      properties: properties,
      created_at: created_at.strftime(DateFormat),
      updated_at: updated_at.strftime(DateFormat),
    }
    hash[:location] = {lat: lat.to_f, lon: lng.to_f} if lat? && lng?
    hash[:parent_ids] = hierarchy.split(',').map(&:to_i) if hierarchy?
    index.store hash
    index.refresh
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
