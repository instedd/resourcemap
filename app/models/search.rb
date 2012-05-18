class Search
  include SearchBase

  class << self
    attr_accessor :page_size
  end
  Search.page_size = 50

  attr_accessor :collection

  def initialize(collection)
    @collection = collection
    @search = collection.new_tire_search
    @from = 0
  end

  def page(page)
    @search.from((page - 1) * self.class.page_size)
    self
  end

  def offset(offset)
    @offset = offset
    self
  end

  def limit(limit)
    @limit = limit
    self
  end

  def sort(es_code, ascendent = true)
    @sort = decode(es_code)
    @sort_ascendent = ascendent ? nil : 'desc'
  end

  def unlimited
    @unlimited = true
  end

  def results
    apply_queries

    if @sort
      sort = @sort
      sort_ascendent = @sort_ascendent
      @search.sort { by sort, sort_ascendent }
    else
      @search.sort { by '_uid' }
    end

    if @offset && @limit
      @search.from @offset
      @search.size @limit
    elsif @unlimited
      @search.size 1_000_000
    else
      @search.size self.class.page_size
    end

    @search.perform.results
  end
end
