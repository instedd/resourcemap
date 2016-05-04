class Field::DateFormat::DateMmDdYyyyFormat < Field::DateFormat::FormatImplementation

  def format_message
    "The configured date format is mm/dd/yyyy."
  end

  def strftime_format
    '%m/%d/%Y'
  end

  def value_hint
    "Example of valid date: 01/25/2013."
  end

  # This is an optimization to avoid parsing the ISO date only to reformat it in
  # another way. Also, Time.iso8601 is pretty slow.
  def api_value(iso_string)
    "#{iso_string[5..6]}/#{iso_string[8..9]}/#{iso_string[0..3]}"
  end

  def human_value(iso_string)
    "#{iso_string[5..6]}/#{iso_string[8..9]}/#{iso_string[0..3]}"
  end
end
