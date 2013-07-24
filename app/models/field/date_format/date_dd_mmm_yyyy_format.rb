class Field::DateFormat::DateDdMmmYyyyFormat < Field::DateFormat::FormatImplementation

  def format_message()
    "The configured date format is dd/mmm/yyyy."
  end

  def value_hint
    "Example of valid date: 08/May/2013."
  end

  def parse_date(dd_mmmm_yyyy_value)
    Time.strptime dd_mmmm_yyyy_value, '%d/%b/%Y'
  end

end
