module Collection::GeomConcern
  extend ActiveSupport::Concern

  # Inovke this method to compute this collection's geometry in memory,
  # just before saving it.
  #
  # (Putting as a before_create callback doesn't seem to work, the sites are empty)
  def compute_geometry_in_memory
    sites_with_location = sites.select{|x| x.lat && x.lng}
    if sites_with_location.length > 0
      lats = sites_with_location.map(&:lat)
      lngs = sites_with_location.map(&:lng)

      self.lat = lats.sum / lats.length
      self.lng = lngs.sum / lngs.length
    end
  end

  def compute_center
    sites.where('lat is not null && lng is not null').select('sum(lat) as v1, sum(lng) as v2, count(*) as v3').each do |v|
      if v.v1 && v.v2 && v.v3
        self.lat = v.v1 / v.v3
        self.lng = v.v2 / v.v3
      end
    end
  end

  def compute_center!
    compute_center
    save!
  end
end
