class Field::DateField < Field

  def format_implementation
    format = if config && config['format']
      config['format']
    else
      "mm_dd_yyyy"
    end
    class_name = "date_#{format}_format".classify
    "Field::DateFormat::#{class_name}".constantize.new(self)
  end

  def value_type_description
    "dates"
  end

  def decode(value)
    format_implementation.decode(value)
  end

  def format_message()
    format_implementation.format_message()
  end

  def parse_date(value)
    format_implementation.parse_date(value)
  end

  def value_hint
    format_implementation.value_hint()
  end

  def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
    validated_value = {}
    iso_date_from = format_implementation.decode(parse_date_from(value))
    validated_value[:date_from] =  iso_date_from if valid_value?(iso_date_from)
    iso_date_to = format_implementation.decode(parse_date_to(value))
    validated_value[:date_to] = iso_date_to if valid_value?(iso_date_to)
    validated_value
  end

  def decode_from_ui(value)
    begin
      format_implementation.decode(value)
    rescue
      value
    end
  end

  def api_value(value)
    format_implementation.api_value(value)
  end

  def human_value(value)
    format_implementation.human_value(value)
  end

  def decode_fred(iso_string_value)
    # FRED API uses iso8601 format in updates, so we dont need to decode any value
    # If this value is not an iso string, an exception will be thrown in the site's validation.
    iso_string_value
  end

  def valid_value?(value, site = nil)
    begin
      time = Time.iso8601(value)
      iso_value = format_date_iso_string(time)
      raise "invalid" unless iso_value == value
    rescue
      raise invalid_field_message()
    end
    true
  end

  def format_date_iso_string(time)
    time.strftime "%Y-%m-%dT00:00:00Z"
  end


  def invalid_field_message()
    "Invalid date value in field #{code}. #{format_implementation.format_message()}"
  end

  private


  def parse_date_from(value)
    match = (value.match /(.*),/)
    if match.nil?
      raise invalid_field_message
    end
    match.captures[0]
  end

  def parse_date_to(value)
    match = (value.match /,(.*)/)
    if match.nil?
      raise invalid_field_message
    end
    match.captures[0]
  end

end
