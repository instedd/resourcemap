class Field::DateFormat::FormatImplementation
  def initialize(field)
    @field = field
  end

  def decode(value)
    begin
      convert_to_iso8601_string(value)
    rescue
      raise @field.invalid_field_message()
    end
  end

  def parse_date(value)
    Time.strptime value, strftime_format
  end

  def api_value(iso_string)
    Time.iso8601(iso_string).strftime(strftime_format)
  end

  def convert_to_iso8601_string(value)
    @field.format_date_iso_string(parse_date(value))
  end
end
