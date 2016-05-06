module SearchBase
  def use_codes_instead_of_es_codes
    @use_codes_instead_of_es_codes = true
    self
  end

  def id(id)
    if id.is_a?(Array)
      add_filter terms: {id: id}
    else
      add_filter term: {id: id}
    end
    self
  end

  def name_start_with(name)
    add_filter prefix: {name: name.downcase}
  end

  def name(name)
    add_filter term: {"name.downcase" => name.downcase}
  end

  def name_search(name)
    add_query prefix: {name: name.downcase}
  end

  def uuid(uuid)
    add_filter term: {uuid: uuid}
  end

  def eq(field, value)
    if value.blank?
      add_filter missing: {field: field.es_code}
      return self
    end

    query_params = query_params(field, value)
    add_filter query_params

    self
  end

  def not_eq(field, value)
    query_params = query_params(field, value)
    add_filter not: query_params
    self
  end

  def query_params(field, value)
    query_key = field.es_code
    validated_value = field.parse_for_query(value, @use_codes_instead_of_es_codes)

    if field.kind == 'date'
      date_field_range(query_key, validated_value)
    elsif field.kind == 'yes_no' && !validated_value.is_a?(Array) && !Field.yes?(value)
      { not: { :term => { query_key => true }}} # so we return false & nil values
    elsif validated_value.is_a? Array
      { terms: {query_key => validated_value} }
    else
      { term: {query_key => validated_value} }
    end

    # elsif field.select_kind?
    #   {term: {query_key => validated_value}}
    #   add_filter term: {query_key => validated_value}
    # else
    # end

  end

  def date_field_range(key, valid_value)
    date_from = valid_value[:date_from]
    date_to = valid_value[:date_to]

    { range: { key => { gte: date_from, lte: date_to } } }
  end

  def under(field, value)
    if value.blank?
      add_filter missing: {field: field.es_code}
      return self
    end

    value = field.descendants_of_in_hierarchy value
    query_key = field.es_code
    add_filter terms: {query_key => value}
    self
  end

  def starts_with(field, value)
    validated_value = field.apply_format_query_validation(value, @use_codes_instead_of_es_codes)
    query_key = field.es_code
    add_prefix key: query_key, value: validated_value
    self
  end

  ['lt', 'lte', 'gt', 'gte'].each do |op|
    class_eval %Q(
      def #{op}(field, value)
        validated_value = field.apply_format_query_validation(value, @use_codes_instead_of_es_codes)
        add_filter range: {field.es_code => {#{op}: validated_value}}
        self
      end
    )
  end

  def op(field, op, value)
    case op.to_s.downcase
    when '<', 'l' then lt(field, value)
    when '<=', 'lte' then lte(field, value)
    when '>', 'gt' then gt(field, value)
    when '>=', 'gte' then gte(field, value)
    when '=', '==', 'eq' then eq(field, value)
    when '!=' then not_eq(field, value)
    when 'under' then under(field, value)
    else raise "Invalid operation: #{op}"
    end
    self
  end

  def where(properties = {})
    properties.each do |es_code, value|
      field = check_field_exists es_code

      if value.is_a? String
        case
        when value[0 .. 1] == '<=' then lte(field, value[2 .. -1].strip)
        when value[0] == '<' then lt(field, value[1 .. -1].strip)
        when value[0 .. 1] == '>=' then gte(field, value[2 .. -1].strip)
        when value[0] == '>' then gt(field, value[1 .. -1].strip)
        when value[0] == '=' then eq(field, value[1 .. -1].strip)
        when value[0 .. 1] == '~=' then starts_with(field, value[2 .. -1].strip)
        else eq(field, value)
        end
      elsif value.is_a? Hash
        value.each { |pair| op(field, pair[0], pair[1]) }
      else
        eq(field, value)
      end
    end
    self
  end


  # Set a really large number for site parameter, since ES does not have a way to return all terms matching the hits
  # https://github.com/elasticsearch/elasticsearch/issues/1776
  # The number I put here is the max integer in Java
  def histogram_search(field_es_code, filters=nil)
    facets_hash = {
      terms: {
        field: field_es_code,
        size: 2147483647,
        all_terms: true,
      }
    }

    if filters.present?
      query_params = query_params(filters.keys.first, filters.values.first)
      query_hash = {facet_filter: {and: [query_params]} }
      facets_hash.merge!(query_hash)
    end

    add_facet "field_#{field_es_code}_ratings", facets_hash

    self
  end


  def before(time)
    time = parse_time(time)
    add_filter range: {updated_at: {lte: Site.format_date(time)}}
    self
  end

  def after(time)
    time = parse_time(time)
    updated_since_query(time)
  end

  def updated_since(iso_string)
    time = Time.iso8601(iso_string)
    updated_since_query(time)
  end

  def updated_since_query(time)
    add_filter range: {updated_at: {gte: Site.format_date(time)}}
    self
  end

  def created_after(time)
    time = parse_time(time)
    created_since_query(time)
  end

  def created_since_query(time)
    add_filter range: {created_at: {gte: Site.format_date(time)}}
    self
  end

  def date_query(iso_string, field_name)
    # We use a 2 seconds range, not the exact date, because this would be very restrictive
    time = Time.iso8601(iso_string)
    time_upper_bound = time + 1.second
    time_lower_bound = time - 1.second
    add_filter range: {field_name.to_sym => {gte: Site.format_date(time_lower_bound)}}
    add_filter range: {field_name.to_sym => {lte: Site.format_date(time_upper_bound)}}
    self
  end

  def updated_at(iso_string)
    date_query(iso_string, 'updated_at')
  end

  def created_at(iso_string)
    date_query(iso_string, 'created_at')
  end

  def full_text_search(text)
    query = ElasticSearch::QueryHelper.full_text_search(text, self, collection, fields)
    add_query query_string: {query: query} if query
    self
  end

  def box(west, south, east, north)
    add_filter geo_bounding_box: {
      location: {
        top_left: {
          lat: north,
          lon: west
        },
        bottom_right: {
          lat: south,
          lon: east
        },
      }
    }
    self
  end

  def radius(lat, lng, meters)
    meters = meters.to_f unless meters.is_a?(String) && (meters.end_with?('km') || meters.end_with?('mi'))
    add_filter geo_distance: {
      distance: meters,
      location: { lat: lat, lon: lng }
    }
    self
  end

  def field_exists(field_code)
    add_filter exists: {field: field_code}
  end

  def require_location
    add_filter exists: {field: :location}
    self
  end

  def location_missing
    add_filter not: {exists: {field: :location}}
    self
  end

  def hierarchy(es_code, value)
    field = check_field_exists es_code
    if value.present?
      eq field, value
    else
      add_filter not: {exists: {field: es_code}}
    end
  end

  def deleted_since(time)
    time = parse_time(time)
    add_filter range: {deleted_at: {gte: Site.format_date(time)}}
    only_deleted
  end

  # Shows only deleted sites
  def only_deleted
    @deleted = :only_deleted
  end

  # Shows deleted and non-deleted sites
  def show_deleted
    @deleted = :show
  end

  def get_body
    body = {}

    case @deleted
    when :only_deleted
      add_filter exists: {field: "deleted_at"}
    when :show
      # Nothing
    else
      add_filter missing: {field: "deleted_at"}
    end

    if @filters
      if @filters.length == 1
        body[:filter] = @filters.first
      else
        body[:filter] = {and: @filters}
      end
    end

    if @facets
      body[:facets] = @facets
    end

    all_queries = []

    if @prefixes
      prefixes = @prefixes.map { |prefix| {prefix: {prefix[:key] => prefix[:value]}} }
      all_queries.concat prefixes
    end

    if @queries
      all_queries.concat @queries
    end

    case all_queries.length
    when 0
      # Nothing to do
    when 1
      body[:query] = all_queries.first
    else
      body[:query] = {bool: {must: all_queries}}
    end

    body
  end

  def select_fields(fields_array)
    @select_fields = fields_array
    self
  end

  def add_filter(filter)
    @filters ||= []
    @filters.push filter
  end

  def add_facet(name, value)
    @facets ||= {}
    @facets[name] = value
  end

  private

  def decode(code)
    return code unless @use_codes_instead_of_es_codes

    code = remove_at_from_code code
    fields.find { |x| x.code == code }.es_code
  end

  def remove_at_from_code(code)
    code.start_with?('@') ? code[1 .. -1] : code
  end

  def add_query(query)
    @queries ||= []
    @queries.push query
  end

  def add_prefix(query)
    @prefixes ||= []
    @prefixes.push query
  end

  def parse_time(time)
    if time.is_a? String
      time = case time
      when /last(_|\s*)hour/i then Time.now - 1.hour
      when /last(_|\s*)day/i then Time.now - 1.day
      when /last(_|\s*)week/i then Time.now - 1.week
      when /last(_|\s*)month/i then Time.now - 1.month
      else Time.parse(time)
      end
    end
    time
  end

  def check_field_exists(code)
    if @use_codes_instead_of_es_codes
      code = remove_at_from_code code
      fields_with_code = fields.select{|f| f.code == code}
      raise "Unknown field: #{code}" unless fields_with_code.length > 0
      fields_with_code[0]
    else
      fields_with_es_code = fields.select{|f| f.es_code == code}
      raise "Unknown field: #{code}" unless fields_with_es_code.length > 0
      fields_with_es_code[0]
    end
  end

  def fields
    @_fields_ ||= collection.fields
  end

  def to_curl(client, body)
    info = client.transport.hosts.first
    protocol, host, port = info[:protocol], info[:host], info[:port]

    url = "#{protocol}://#{host}:#{port}/#{@index_names}/site/_search"

    body = body.to_json.gsub("'",'\u0027')
    "curl -X GET '#{url}?pretty' -d '#{body}'"
  end
end
