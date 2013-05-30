class Search
  include SearchBase

  class << self
    attr_accessor :page_size
  end
  Search.page_size = 50

  attr_accessor :collection

  def initialize(collection, options)
    @collection = collection
    @search = collection.new_tire_search(options)
    @snapshot_id = options[:snapshot_id]
    if options[:current_user]
      @current_user = options[:current_user]
    else
      @current_user = User.find options[:current_user_id] if options[:current_user_id]
    end
    @sort_list = {}
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
    if es_code == 'id' || es_code == 'name' || es_code == 'name_not_analyzed'
      sort = es_code == 'name' ? 'name_not_analyzed' : es_code
    else
      sort = decode(es_code)
    end
    @sort = true
    ascendant = ascendent ? 'asc' : 'desc'
    @sort_list[sort] = ascendant
    self
  end

  def sort_multiple(sort_list)
    sort_list.each_pair do |es_code, ascendent|
      sort(es_code, ascendent)
    end
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
    sort_list = @sort_list
    if @sort
      @search.sort { by sort_list }
    else
      @search.sort { by 'name_not_analyzed' }
    end

    if @offset && @limit
      @search.from @offset
      @search.size @limit
    elsif @unlimited
      @search.size 1_000_000
    else
      @search.size self.class.page_size
    end

    Rails.logger.debug @search.to_curl if Rails.logger.level <= Logger::DEBUG

    @search.perform.results
  end

  # Returns the results from ElasticSearch but with codes as keys and codes as
  # values (when applicable).
  def api_results
    visible_fields = @collection.visible_fields_for(@current_user, snapshot_id: @snapshot_id)

    fields_by_es_code = visible_fields.index_by &:es_code

    items = results()

    items.each do |item|
      properties = item['_source']['properties']
      item['_source']['identifiers'] = []
      item['_source']['properties'] = {}

      properties.each_pair do |es_code, value|
        field = fields_by_es_code[es_code]
        if field
          item['_source']['properties'][field.code] = field.api_value(value)
        end
      end
    end

    items
  end

  # Returns the results from ElasticSearch but with the location field
  # returned as lat/lng fields, and the date as a date object
  def ui_results
    fields_by_es_code = @collection.visible_fields_for(@current_user, snapshot_id: @snapshot_id).index_by &:es_code

    items = results()
    items.each do |item|
      if item['_source']['location']
        item['_source']['lat'] = item['_source']['location']['lat']
        item['_source']['lng'] = item['_source']['location']['lon']
        item['_source'].delete 'location'
      end
      item['_source']['created_at'] = Site.parse_time item['_source']['created_at']
      item['_source']['updated_at'] = Site.parse_time item['_source']['updated_at']
      item['_source']['properties'] = item['_source']['properties'].select { |es_code, value|
        fields_by_es_code[es_code]
      }
    end

    items
  end
end
