class MapSearch
  include SearchBase

  def initialize(collection_ids, options = {})
    @collection_ids = Array(collection_ids)
    @search = Collection.new_tire_search(*@collection_ids, options)
    @search.size 100000
    @bounds = {s: -90, n: 90, w: -180, e: 180}
    @hierarchy = {}
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

  def selected_hierarchy(hierarchy_code, selected_hierarchy)
    @hierarchy[:code] = hierarchy_code
    @hierarchy[:selected] = selected_hierarchy
  end

  def results
    return {} if @collection_ids.empty?

    listener = clusterer = Clusterer.new(@zoom)
    clusterer.highlight @hierarchy if @hierarchy
    listener = ElasticSearch::SitesAdapter::SkipIdListener.new(listener, @exclude_id) if @exclude_id

    set_bounds_filter
    apply_queries

    adapter = ElasticSearch::SitesAdapter.new listener
    adapter.return_property @hierarchy[:code] if @hierarchy[:code]

    Rails.logger.debug @search.to_curl if Rails.logger.level <= Logger::DEBUG

    adapter.parse @search.stream

    clusterer.clusters
  end

  private

  def set_bounds_filter
    if @zoom
      width, height = Clusterer.cell_size_for @zoom
      extend_to_cell_limits width, height
      adjust_bounds_to_world_limits
    end

    @search.filter :exists, field: :location
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

  def adjust_bounds_to_world_limits
    #See https://github.com/elasticsearch/elasticsearch/pull/1602#issuecomment-5978326
    @bounds[:n] = 89.99 if @bounds[:n].to_f > 90
    @bounds[:s] = -89.99 if @bounds[:s].to_f < -90
    @bounds[:e] = 179.99 if @bounds[:e].to_f > 180
    @bounds[:w] = -179.99 if @bounds[:w].to_f < -180
  end

  def collection
    @collection ||= Collection.find @collection_ids[0]
  end
end
