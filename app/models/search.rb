class Search
  def initialize(collection_ids)
    @collection_ids = Array(collection_ids)
    @search = Tire::Search::Search.new @collection_ids.map{|id| Collection.index_name id}
    @search.filter :type, {:value => :site}
    @search.size 100000
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

  def sites
    Site.find results.map{|x| x["_id"]}
  end

  def results
    @collection_ids.empty? ? [] : @search.perform.results
  end
end
