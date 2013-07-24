class Field::DateFormat::DateDdMmYyyyFormat < Field::DateFormat::FormatImplementation

  def format_message
    "The configured date format is dd/mm/yyyy."
  end

  def value_hint
    "Example of valid date: 08/05/2013."
  end

  def parse_date(dd_mm_yyyy_value)
    Time.strptime dd_mm_yyyy_value, '%d/%m/%Y'
  end

end
