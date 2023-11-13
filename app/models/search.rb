class Search
  include SearchBase

  class Results
    include Enumerable

    attr_reader :sites
    attr_reader :page
    attr_reader :previous_page
    attr_reader :next_page
    attr_reader :total_pages
    attr_reader :total_count

    def initialize(options)
      @sites = options[:sites]
      @page = options[:page]
      @previous_page = options[:previous_page]
      @next_page = options[:next_page]
      @total_pages = options[:total_pages]
      @total_count = options[:total_count]
    end

    def total
      total_count
    end

    def each(&block)
      @sites.each(&block)
    end

    def [](index)
      @sites[index]
    end

    def empty?
      @sites.empty?
    end

    def length
      @sites.length
    end
  end

  attr_accessor :page_size
  attr_accessor :collection

  def initialize(collection, options)
    @collection = collection
    @index_names = collection.index_names_with_options(options)
    @snapshot_id = options[:snapshot_id]
    if options[:current_user]
      @current_user = options[:current_user]
    else
      @current_user = User.find options[:current_user_id] if options[:current_user_id]
    end
    @from = 0
    @page_size = 50
  end

  def page(page)
    @page = page
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
        sort = "properties.#{field.es_code}.downcase"
      else
        sort = decode(es_code)
      end
    end
    ascendent = ascendent ? 'asc' : 'desc'

    @sorts ||= []
    @sorts.push sort => ascendent

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

  def get_body
    body = super

    if @sorts
      body[:sort] = @sorts
    else
      body[:sort] = 'name.downcase'
    end

    if @select_fields
      body[:fields] = @select_fields
    end

    if @page
      body[:from] = (@page - 1) * page_size
    end

    if @offset && @limit
      body[:from] = @offset
      body[:size] = @limit
    elsif @unlimited
      body[:size] = 1_000_000
    else
      body[:size] = page_size
    end

    body
  end

  def results
    body = get_body

    client = Elasticsearch::Client.new

    if Rails.logger.level <= Logger::DEBUG
      Rails.logger.debug to_curl(client, body)
    end

    results = client.search index: @index_names, type: 'site', body: body

    hits = results["hits"]
    sites = hits["hits"]
    total_count = hits["total"]

    # When selecting fields, the results are returned in an array.
    # We only keep the first element of that array.
    if @select_fields
      sites.each do |site|
        fields = site["fields"]
        if fields
          fields.each do |key, value|
            fields[key] = value.first if value.is_a?(Array)
          end
        end
      end
    end

    results = {sites: sites, total_count: total_count}
    if @page
      results[:page] = @page
      results[:previous_page] = @page - 1 if @page > 1
      results[:total_pages] = (total_count.to_f / page_size).ceil
      if @page < results[:total_pages]
        results[:next_page] = @page + 1
      end
    end
    Results.new(results)
  end

  def mapped_results
    ElasticSearch::ResultsMapper.new(
      results,
      collection: @collection,
      current_user: @current_user,
      snapshot_id: @snapshot_id
    )
  end

  # TODO: deprecate
  # Returns the results from ElasticSearch but with codes as keys and codes as
  # values (when applicable).
  def api_results(human = false)
    mapped_results.for_json(human)
  end

  # TODO: deprecate
  # Returns the results from ElasticSearch but with the location field
  # returned as lat/lng fields, and the date as a date object
  def ui_results
    mapped_results.for_ui
  end

  def histogram_results(field_es_code)
    body = get_body

    client = Elasticsearch::Client.new
    results = client.search index: @index_names, type: 'site', body: body

    histogram = {}
    results["facets"]["field_#{field_es_code}_ratings"]["terms"].each do |item|
      histogram[item["term"]] = item["count"] unless item["count"] == 0
    end
    histogram
  end
end
