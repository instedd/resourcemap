module Site::IndexUtils
  extend self

  DateFormat = "%Y%m%dT%H%M%S.%L%z"

  def store(site, site_id, index, options = {})
    hash = {
      id: site_id,
      name: site.name,
      type: :site,
      properties: site.properties,
      created_at: site.created_at.strftime(DateFormat),
      updated_at: site.updated_at.strftime(DateFormat),
    }

    hash[:location] = {lat: site.lat.to_f, lon: site.lng.to_f} if site.lat? && site.lng?
    hash[:alert] = site.collection.thresholds_test site.properties unless site.is_a? SiteHistory
    result = index.store hash

    if result['error']
      raise "Can't store site in index: #{result['error']}"
    end

    index.refresh unless options[:refresh] == false
  end
end
