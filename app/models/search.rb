class Search
  include SearchBase

  attr_accessor :page_size
  attr_accessor :collection

  def initialize(collection, options)
    @collection = collection
    @search = collection.new_elasticsearch_search(options)
    @snapshot_id = options[:snapshot_id]
    if options[:current_user]
      @current_user = options[:current_user]
    else
      @current_user = User.find options[:current_user_id] if options[:current_user_id]
    end
    @sort_list = {}
    @from = 0
    @page_size = 50
  end

  def to_curl
    @search.to_curl
  end

  def page(page)
    @search.from((page - 1) * self.page_size)
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
    case es_code
    when 'id', 'name.downcase'
      sort = es_code
    when 'name'
      sort = 'name.downcase'
    else
      es_code = remove_at_from_code es_code
      field = fields.find { |x| x.code == es_code || x.es_code == es_code }
      if field && field.kind == 'text'
        sort = "#{field.es_code}.downcase"
      else
        sort = decode(es_code)
      end
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
  def results_with_count
    apply_queries
    sort_list = @sort_list
    if @sort
      @search.sort { by sort_list }
    else
      @search.sort { by 'name.downcase' }
    end

    if @offset && @limit
      @search.from @offset
      @search.size @limit
    elsif @unlimited
      @search.size 1_000_000
    else
      @search.size self.page_size
    end

    Rails.logger.debug @search.to_curl if Rails.logger.level <= Logger::DEBUG

    search = @search.perform
    search_results = search.results

    # In elasticsearch < 1.0 fields didn't return an array.
    # Now it does, so we convert it back to a single element.
    if @has_select_fields
      search_results.results.each do |result|
        fields = result["fields"]
        if fields
          fields.each do |key, value|
            fields[key] = value.first if value.is_a?(Array)
          end
        end
      end
    end

    {sites: search_results, total_count: search.json['hits']['total']}
  end

  def results
    results_with_count[:sites]
  end

  # Returns the results from ElasticSearch but with codes as keys and codes as
  # values (when applicable).
  def api_results
    visible_fields = @collection.visible_fields_for(@current_user, snapshot_id: @snapshot_id)
    visible_fields.each { |field| field.cache_for_read }

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

    items = results_with_count()

    items[:sites].each do |item|
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

  def histogram_results(field_es_code)
    histogram = {}
    @search.results.facets["field_#{field_es_code}_ratings"]["terms"].each do |item|
      histogram[item["term"]] = item["count"] unless item["count"] == 0
    end
    histogram
  end
end
