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

end
