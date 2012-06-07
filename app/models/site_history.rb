class SiteHistory < ActiveRecord::Base
  belongs_to :site
  belongs_to :collection

  serialize :properties, Hash

  DateFormat = "%Y%m%dT%H%M%S.%L%z"

  def store_in(index, options = {})
    hash = {
      id: site_id,
      name: name,
      type: :site,
      properties: properties,
      created_at: created_at.strftime(DateFormat),
      updated_at: updated_at.strftime(DateFormat),
    }

    hash[:location] = {lat: lat.to_f, lon: lng.to_f} if lat? && lng?
    hash[:alert] = collection.thresholds_test properties
    result = index.store hash

    if result['error']
      raise "Can't store site in index: #{result['error']}"
    end

    index.refresh unless options[:refresh] == false
  end

end