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

    set_bounds_filter if @bounds

    clusterer = Clusterer.new @zoom
    adapter = ElasticSearchSitesAdapter.new clusterer
    adapter.parse @search.stream
    clusterer.clusters
  end

  private

  def set_bounds_filter
    if @zoom
      width, height = Clusterer.cell_size_for @zoom
      extend_to_cell_limits @bounds, width, height
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

  def extend_to_cell_limits(bounds, width, height)
    extend_to_limit bounds, :n,  1, height
    extend_to_limit bounds, :s, -1, height
    extend_to_limit bounds, :e,  1, width
    extend_to_limit bounds, :w, -1, width
  end

  def extend_to_limit(bounds, key, sign, size)
    value = bounds[key].to_f / size
    bounds[key] = (sign >= 0 ? value.ceil : value.floor) * size
  end
end
