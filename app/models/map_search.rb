class MapSearch
  include SearchBase

  def initialize(collection_ids)
    @collection_ids = Array(collection_ids)
    @search = Collection.new_tire_search(*@collection_ids)
    @search.size 100000
    @bounds = {s: -90, n: 90, w: -180, e: 180}
  end

  def zoom=(zoom)
    @zoom = zoom
  end

  def bounds=(bounds)
    @bounds = bounds
    adjust_bounds_to_world_limits
  end

  def exclude_id(id)
    @exclude_id = id
  end

  def results
    return {} if @collection_ids.empty?

    listener = clusterer = Clusterer.new(@zoom)
    listener = ElasticSearch::SitesAdapter::SkipIdListener.new(listener, @exclude_id) if @exclude_id

    set_bounds_filter
    apply_queries
    clusterer.groups = @groups if @zoom

    adapter = ElasticSearch::SitesAdapter.new listener
    adapter.parse @search.stream
    clusterer.clusters
  end

  private

  def set_bounds_filter
    if @zoom
      width, height = Clusterer.cell_size_for @zoom
      extend_to_cell_limits width, height
      extend_to_groups_limits
      extend_to_cell_limits width, height
      adjust_bounds_to_world_limits
    end

    @search.filter :geo_bounding_box, location: {
      top_left: {
        lat: @bounds[:n],
        lon: @bounds[:w]
      },
      bottom_right: {
        lat: @bounds[:s],
        lon: @bounds[:e]
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
    sites = Site.where collection_id: @collection_ids
    sites = sites.where group: true
    sites = sites.where('min_zoom <= ? AND ? <= max_zoom', @zoom, @zoom)
    sites = sites.where('max_lat >= ? AND ? >= min_lat', @bounds[:s], @bounds[:n])
    if @bounds[:w] <= @bounds[:e]
      sites = sites.where('max_lng >= ? AND ? >= min_lng', @bounds[:w], @bounds[:e])
    else
      sites = sites.where('(max_lng >= ? AND ? >= min_lng) OR (max_lng >= ? AND ? >= min_lng)', @bounds[:w], 180, -180, @bounds[:e])
    end
    @groups = sites.values_of(:id, :lat, :lng, :min_lat, :max_lat, :min_lng, :max_lng, :max_zoom).map do |id, lat, lng, min_lat, max_lat, min_lng, max_lng, max_zoom|
      @bounds[:n] = max_lat + 0.001 if max_lat > @bounds[:n]
      @bounds[:s] = min_lat - 0.001 if min_lat < @bounds[:s]
      @bounds[:e] = max_lng + 0.001 if max_lng > @bounds[:e]
      @bounds[:w] = min_lng - 0.001 if min_lng < @bounds[:w]

      {id: id, lat: lat, lng: lng, max_zoom: max_zoom}
    end
  end

  def adjust_bounds_to_world_limits
    @bounds[:n] = 90 if @bounds[:n].to_f >= 90
    @bounds[:s] = -90 if @bounds[:s].to_f <= -90
    @bounds[:e] = 180 if @bounds[:e].to_f >= 180
    @bounds[:w] = -180 if @bounds[:w].to_f <= -180
  end

  def collection
    @collection ||= Collection.find @collection_ids[0]
  end
end
