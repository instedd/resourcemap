class Field::DateFormat::DateMmDdYyyyFormat < Field::DateFormat::FormatImplementation

  def format_message()
    "The configured date format is mm/dd/yyyy."
  end

  def value_hint
    "Example of valid date: 01/25/2013."
  end

  def parse_date(m_d_y_value)
    Time.strptime m_d_y_value, '%m/%d/%Y'
  end

end
