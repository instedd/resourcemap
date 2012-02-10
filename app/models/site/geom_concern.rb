module Site::GeomConcern
  extend ActiveSupport::Concern

  included do
    before_save :compute_bounding_box_and_zoom, :unless => :group, :if => lambda { new_record? || lat_changed? || lng_changed? }
    after_save  :compute_parent_bounding_box_and_zoom, :if => lambda { parent_id && (new_record? || lat_changed? || lng_changed? || min_lat_changed? || max_lat_changed? || min_lng_changed? || max_lng_changed?) }
  end

  def compute_bounding_box_and_zoom
    if group
      self.sites.select('min(min_lat) as v1, min(max_lat) as v2, max(min_lat) as v3, max(max_lat) as v4, min(min_lng) as v5, min(max_lng) as v6, max(min_lng) as v7, max(max_lng) as v8').each do |v|
        if v.v1 && v.v2 && v.v3 && v.v4 && v.v5 && v.v6 && v.v7 && v.v8
          self.min_lat = [v.v1, v.v2].min
          self.max_lat = [v.v3, v.v4].max
          self.min_lng = [v.v5, v.v6].min
          self.max_lng = [v.v7, v.v8].max
          max_size = [self.max_lat - self.min_lat, self.max_lng - self.min_lng].max.to_f
          if max_size && max_size > 0
            self.min_zoom = 0
            self.max_zoom = Clusterer.zoom_for(max_size)
            self.sites.update_all "min_zoom = #{self.max_zoom + 1}"
          else
            self.min_zoom = 22
            self.max_zoom = 22
          end
        else
          self.min_zoom = 22
          self.max_zoom = 22
        end
      end
    else
      self.min_lat = self.max_lat = lat
      self.min_lng = self.max_lng = lng
    end
  end

  def compute_bounding_box_and_zoom!
    compute_bounding_box_and_zoom
    self.save!
  end

  def compute_parent_bounding_box_and_zoom
    parent.compute_bounding_box_and_zoom!
  end
end
