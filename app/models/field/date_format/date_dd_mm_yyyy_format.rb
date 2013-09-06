class Field::DateFormat::DateDdMmYyyyFormat < Field::DateFormat::FormatImplementation

  def format_message
    "The configured date format is dd/mm/yyyy."
  end

  def strftime_format
    '%d/%m/%Y'
  end

  def value_hint
    "Example of valid date: 25/01/2013."
  end


end
