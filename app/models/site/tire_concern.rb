module Site::TireConcern
  extend ActiveSupport::Concern

  DateFormat = "%Y%m%dT%H%M%S.%L%z"

  included do
    after_save :store_in_index, :unless => :group?, :if => lambda { lat? && lng? }
    after_destroy :remove_from_index, :unless => :group?, :if => lambda { lat? && lng? }

    delegate :index_name, :index, to: :collection
  end

  def store_in_index
    index.store({
      id: id,
      type: :site,
      location: {lat: lat.to_f, lon: lng.to_f},
      properties: properties,
      created_at: created_at.strftime(DateFormat),
      updated_at: updated_at.strftime(DateFormat),
      parent_ids: hierarchy ? hierarchy.split(',').map(&:to_i) : nil
    })
    index.refresh
  end

  def remove_from_index
    index.remove id: id, type: :site
    index.refresh
  end

  module ClassMethods
    def parse_date(date)
      DateTime.strptime(date, DateFormat)
    end
  end
end
