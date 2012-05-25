module Collection::GeomConcern
  extend ActiveSupport::Concern

  # Inovke this method to compute this collection's geometry in memory,
  # just before saving it.
  #
  # (Putting as a before_create callback doesn't seem to work, the sites are empty)
  def compute_geometry_in_memory
    sites_with_location = sites.select{|x| x.lat && x.lng}
    min_lat, max_lat, min_lng, max_lng = 90, -90, 180, -180
    sites_with_location.each do |site|
      min_lat = site.lat if site.lat < min_lat
      max_lat = site.lat if site.lat > max_lat
      min_lng = site.lng if site.lng < min_lng
      max_lng = site.lng if site.lng > max_lng
    end
    set_bounding_box min_lat, max_lat, min_lng, max_lng
  end

  def compute_bounding_box
    sites.where('lat is not null && lng is not null').select('min(lat) as v1, max(lat) as v2, min(lng) as v3, max(lng) as v4').each do |v|
      set_bounding_box v.v1, v.v2, v.v3, v.v4 if v.v1 && v.v2 && v.v3 && v.v4
    end
  end

  def set_bounding_box(min_lat, max_lat, min_lng, max_lng)
    self.min_lat = min_lat
    self.max_lat = max_lat
    self.min_lng = min_lng
    self.max_lng = max_lng
    self.lat = (min_lat + max_lat) / 2
    self.lng = (min_lng + max_lng) / 2
  end

  def compute_bounding_box!
    compute_bounding_box
    save!
  end
end
