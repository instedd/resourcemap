class Search
  def initialize(collection_id)
    @search = Collection.new_tire_search(collection_id)
  end

  def eq(property, value)
    @search.filter :term, property => value
  end

  def where(properties = {})
    properties.each { |property, value| eq(property, value) }
  end

  def results
    @search.perform.results
  end
end
