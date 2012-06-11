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
    if es_code == 'id' || es_code == 'name'
      @sort = es_code
    else
      @sort = decode(es_code)
    end
    @sort_ascendent = ascendent ? nil : 'desc'
    self
  end

  def unlimited
    @unlimited = true
    self
  end

  # Returns the results from ElasticSearch without modifications. Keys are ids
  # and so are values (when applicable).
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

  # Returns the results from ElasticSearch but with codes as keys and codes as
  # values (when applicable).
  def api_results
    fields_by_es_code = fields.index_by &:es_code

    items = results()
    items.each do |item|
      item['_source']['properties'] = Hash[
        item['_source']['properties'].map do |es_code, value|
          field = fields_by_es_code[es_code]
          field ? [field.code, field.api_value(value)] : [es_code, value]
        end
      ]
    end
    items
  end

  # Returns the results from ElasticSearch but with the location field
  # returned as lat/lng fields, and the date as a date object
  def ui_results
    items = results()
    items.each do |item|
      if item['_source']['location']
        item['_source']['lat'] = item['_source']['location']['lat']
        item['_source']['lng'] = item['_source']['location']['lon']
        item['_source'].delete 'location'
      end
      item['_source']['created_at'] = Site.parse_date item['_source']['created_at']
      item['_source']['updated_at'] = Site.parse_date item['_source']['updated_at']
    end
    items
  end
end
