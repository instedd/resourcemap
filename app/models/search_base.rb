# Include this module to get search methods that will modify
# a @search instance that must be a Tire::Search object.
#
# The class that includes this module must provide a collection
# method that returns the collection being searched.
#
# Before executing the search you must invoke apply_queries.
module SearchBase
  def use_codes_instead_of_es_codes
    @use_codes_instead_of_es_codes = true
    self
  end

  def id(id)
    @search.filter :term, id: id
    self
  end

  def name_start_with(name)
    @search.filter :prefix, name: name.downcase
  end

  def eq(field, value)

    apply_format_validation(field, value)
    query_key = field.es_code

    if field.kind == 'date'
      date_field_range(query_key, value)
    elsif field.kind == 'hierarchy' and value.is_a? Array
      query_value = decode_hierarchy_option(field, query_key, value)
      @search.filter :terms, query_key => query_value
    elsif field.select_kind?
      query_value = decode_option(field, query_key, value)
      @search.filter :term, query_key => query_value
      self
    else
      @search.filter :term, query_key => value
      self
    end
  end

  def starts_with(field, value)
    apply_format_validation(field, value)

    query_key = field.es_code

    if field.select_kind?
      query_value = decode_option(field, query_key, value)
    else
      query_value = value
    end

    add_prefix key: query_key, value: query_value
    self
  end

  ['lt', 'lte', 'gt', 'gte'].each do |op|
    class_eval %Q(
      def #{op}(field, value)

        apply_format_validation(field, value)

        @search.filter :range, field.es_code => {#{op}: value}
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

  def date_field_range(key, value)
    date_from_time = Time.strptime(parse_date_from(value), '%m/%d/%Y')
    date_to_time = Time.strptime(parse_date_to(value), '%m/%d/%Y')

    date_from = date_from_time.iso8601
    date_to = date_to_time.iso8601

    @search.filter :range, key => {gte: date_from, lte: date_to}
    self
  end

  def before(time)
    time = parse_time(time)
    @search.filter :range, updated_at: {lte: Site.format_date(time)}
    self
  end

  def after(time)
    time = parse_time(time)
    @search.filter :range, updated_at: {gte: Site.format_date(time)}
    self
  end

  def full_text_search(text)
    query = ElasticSearch::QueryHelper.full_text_search(text, @search, collection, fields)
    add_query query if query
    self
  end

  def box(west, south, east, north)
    @search.filter :geo_bounding_box, location: {
      top_left: {
        lat: north,
        lon: west
      },
      bottom_right: {
        lat: south,
        lon: east
      },
    }
    self
  end

  def radius(lat, lng, meters)
    meters = meters.to_f / 1000 unless meters.is_a?(String) && (meters.end_with?('km') || meters.end_with?('mi'))
    @search.filter :geo_distance,
      distance: meters,
      location: { lat: lat, lon: lng }
    self
  end

  def require_location
    @search.filter :exists, field: :location
    self
  end

  def location_missing
    @search.filter :not, {exists: {field: :location}}
    self
  end

  def hierarchy(es_code, value)
    field = check_field_exists es_code
    if value.present?
      eq field, value
    else
      @search.filter :not, {exists: {field: es_code}}
    end
  end

  def apply_queries
    @search.query { |q|
      query = @queries.join " AND " if @queries
      case
      when @queries && @prefixes
        q.boolean do |bool|
          bool.must { |q| q.string query }
          apply_prefixes bool
        end
      when @queries && !@prefixes then q.string query
      when !@queries && @prefixes then apply_prefixes q
      else q.all
      end
    }
  end

  def select_fields(fields_array)
    @search.fields(fields_array)
    self
  end

  private

  def apply_prefixes to
    if to.is_a? Tire::Search::BooleanQuery
      @prefixes.each do |prefix|
        to.must { |q| q.prefix prefix[:key], prefix[:value] }
      end
    else
      if @prefixes.length == 1
        to.prefix @prefixes.first[:key], @prefixes.first[:value]
      else
        to.boolean { |bool| apply_prefixes bool }
      end
    end
  end

  def decode(code)
    return code unless @use_codes_instead_of_es_codes

    code = remove_at_from_code code
    fields.find { |x| x.code == code }.es_code
  end

  def remove_at_from_code(code)
    code.start_with?('@') ? code[1 .. -1] : code
  end

  def decode_option(field, es_code, value)
    if field && field.config && field.config['options']
      value_id = check_option_exists(field, value)
    end
    value_id
  end

  def decode_hierarchy_option(field, es_code, array_value)
    return array_value unless @use_codes_instead_of_es_codes

    value_ids = []
    if field && field.config && field.config['hierarchy']
      array_value.each do |value|
        value_id = check_option_exists(field, value)
        value_ids << value_id
      end
    end
    value_ids
  end

  def add_query(query)
    @queries ||= []
    @queries.push query
  end

  def add_prefix(query)
    @prefixes ||= []
    @prefixes.push query
  end

  def parse_date_from(info)
    match = (info.match /(.*),/)
    match.captures[0]
  end


  def parse_date_to(info)
    match = (info.match /,(.*)/)
    match.captures[0]
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

  def apply_format_validation(field, value)
    check_precense_of_value(value, field.code)

    if field.kind == 'numeric'
      validated_value = check_valid_numeric_value(value, field.code)
    elsif field.kind == 'date'
      validated_value = {}
      validated_value[:date_from] = Time.strptime(parse_date_from(value), '%m/%d/%Y') rescue (raise "Invalid date value in #{field.code} param")
      validated_value[:date_to] = Time.strptime(parse_date_to(value), '%m/%d/%Y') rescue (raise "Invalid date value in #{field.code} param")
    elsif field.kind == 'hierarchy'
      validated_value = check_option_exists(field, value.first)
    elsif field.select_kind?
      validated_value = check_option_exists(field, value)
    end
    validated_value
  end

  def check_option_exists(field, value)
    value_id = nil
    if field.kind == 'hierarchy'
      if @use_codes_instead_of_es_codes
        value_id = field.find_hierarchy_id_by_name(value)
      else
        value_id = value unless !field.hierarchy_options_codes.include? value
      end
    elsif field.select_kind?
      field.config['options'].each do |option|
        if @use_codes_instead_of_es_codes
          value_id = option['id'] if option['label'] == value || option['code'] == value
        else
          value_id = value if field.config["options"].any?{|opt| opt["id"].to_s == value}
        end
      end
    end
    raise "Invalid option in #{field.code} param" unless !value_id.nil?
    value_id
  end

  def check_valid_numeric_value(value, field_code)
    raise "Invalid numeric value in #{field_code} param" unless value.integer?
    value
  end

  def integer?(string)
    true if Integer(string) rescue false
  end

  def check_precense_of_value(value, field_code)
    raise "Missing #{field_code} value" unless !value.blank?
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
    @_fields_ ||= collection.fields.all
  end
end
