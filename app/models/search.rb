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

  def in_group(site)
    site = Site.find(site) unless site.is_a? Site
    parent_ids = (site.hierarchy || '').split(',').map(&:to_i)
    parent_ids << site.id
    parent_ids.each do |parent_id|
      @search.filter :term, parent_ids: parent_id
    end
    self
  end

  def sort(field, ascendent = true)
    @sort = field
    @sort_ascendent = ascendent ? nil : 'desc'
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
    else
      @search.size self.class.page_size
    end

    decode_elastic_search_results @search.perform.results
  end

  private

end
