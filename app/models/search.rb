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
    @search.filter :geo_bounding_box, :location => {
      :top_left => {
        :lat => bounds[:n],
        :lon => bounds[:w]
      },
      :bottom_right => {
        :lat => bounds[:s],
        :lon => bounds[:e]
      },
    }
  end

  def results
    return {} if @collection_ids.empty?

    clusterer = Clusterer.new @zoom
    adapter = ElasticSearchSitesAdapter.new clusterer
    adapter.parse @search.stream
    clusterer.clusters
  end

  def to_curl
    @search.to_curl
  end
end
