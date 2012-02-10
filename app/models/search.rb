class Search
  def initialize(collection_ids)
    @collection_ids = Array(collection_ids)
    @search = Tire::Search::Search.new @collection_ids.map{|id| Collection.index_name id}
    @search.filter :type, {:value => :site}
    @search.size 100000
  end

  def zoom=(zoom)
    @zoom = zoom
  end

  def bounds=(bounds)
    @bounds = bounds
    @bounds[:n] = 90 if @bounds[:n].to_f >= 90
    @bounds[:s] = -90 if @bounds[:s].to_f <= -90
    @bounds[:e] = 180 if @bounds[:e].to_f >= 180
    @bounds[:w] = -180 if @bounds[:w].to_f <= -180
  end

  def results
    return {} if @collection_ids.empty?

    clusterer = Clusterer.new @zoom

    if @bounds
      set_bounds_filter
      clusterer.groups = @groups if @zoom
    end

    adapter = ElasticSearchSitesAdapter.new clusterer
    adapter.parse @search.stream
    clusterer.clusters
  end

  private

  def set_bounds_filter
    if @zoom
      width, height = Clusterer.cell_size_for @zoom
      extend_to_cell_limits width, height
      extend_to_groups_limits
    end
    @search.filter :geo_bounding_box, :location => {
      :top_left => {
        :lat => @bounds[:n],
        :lon => @bounds[:w]
      },
      :bottom_right => {
        :lat => @bounds[:s],
        :lon => @bounds[:e]
      },
    }
  end

  def extend_to_cell_limits(width, height)
    extend_to_limit :n,  1, height
    extend_to_limit :s, -1, height
    extend_to_limit :e,  1, width
    extend_to_limit :w, -1, width
  end

  def extend_to_limit(key, sign, size)
    value = @bounds[key].to_f / size
    @bounds[key] = (sign >= 0 ? value.ceil : value.floor) * size
  end

  def extend_to_groups_limits
    sites = Site.where(:collection_id => @collection_ids)
    sites = sites.where(:group => true)
    sites = sites.where('min_zoom <= ? && ? <= max_zoom', @zoom, @zoom)
    sites = sites.where('max_lat >= ? && ? >= min_lat', @bounds[:s], @bounds[:n])
    sites = sites.where('max_lng >= ? && ? >= min_lng', @bounds[:w], @bounds[:e])
    @groups = sites.values_of(:id, :lat, :lng, :min_lat, :max_lat, :min_lng, :max_lng).map do |id, lat, lng, min_lat, max_lat, min_lng, max_lng|
      @bounds[:n] = max_lat + 0.001 if max_lat > @bounds[:n]
      @bounds[:s] = min_lat - 0.001 if min_lat < @bounds[:s]
      @bounds[:e] = max_lng + 0.001 if max_lng > @bounds[:e]
      @bounds[:w] = min_lng - 0.001 if min_lng < @bounds[:w]

      {:id => id, :lat => lat, :lng => lng}
    end
  end
end
