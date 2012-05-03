# Include this module to get search methods that will modify
# a @search instance that must be a Tire::Search object.
#
# The class that includes this module must provide a collection
# method that returns the collection being searched.
#
# Before executing the search you must invoke apply_queries.
module SearchBase
  def id(id)
    @search.filter :term, id: id
    self
  end

  def eq(property, value)
    check_field_exists property

    query_key = Site.encode_elastic_search_keyword(property)
    query_value = property_value(property.to_s, value)
    add_query %Q(#{query_key}:"#{query_value}")
    self
  end

  ['lt', 'lte', 'gt', 'gte'].each do |op|
    class_eval %Q(
      def #{op}(property, value)
        check_field_exists property

        @search.filter :range, Site.encode_elastic_search_keyword(property) => {#{op}: value}
        self
      end
    )
  end

  def op(property, op, value)
    case op.to_s.downcase
    when '<', 'l' then lt(property, value)
    when '<=', 'lte' then lte(property, value)
    when '>', 'gt' then gt(property, value)
    when '>=', 'gte' then gte(property, value)
    when '=', '==', 'eq' then eq(property, value)
    else raise "Invalid operation: #{op}"
    end
    self
  end

  def where(properties = {})
    properties.each do |property, value|
      if value.is_a? String
        case
        when value[0 .. 1] == '<=' then lte(property, value[2 .. -1].strip)
        when value[0] == '<' then lt(property, value[1 .. -1].strip)
        when value[0 .. 1] == '>=' then gte(property, value[2 .. -1].strip)
        when value[0] == '>' then gt(property, value[1 .. -1].strip)
        when value[0] == '=' then eq(property, value[1 .. -1].strip)
        else eq(property, value)
        end
      else
        eq(property, value)
      end
    end
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

  def apply_queries
    if @queries
      query = @queries.join " AND "
      @search.query { string query }
    end
  end

  private

  def decode_elastic_search_results(results)
    results.each do |result|
      result['_source']['properties'] = Site.decode_elastic_search_keywords(result['_source']['properties'])
    end
    results
  end

  def property_value(property, value)
    field = fields.find { |x| x.code == property }
    if field && field.config && field.config['options']
      field.config['options'].each do |option|
        return option['code'] if option['label'] == value
      end
    end
    value
  end

  def add_query(query)
    @queries ||= []
    @queries.push query
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

  def check_field_exists(name)
    name = Site.decode_elastic_search_keyword name.to_s
    raise "Unknown field: #{name}" unless fields.any?{|f| f.code == name}
  end

  def fields
    @_fields_ ||= collection.fields.all
  end
end
