class Field::DateField < Field
  def value_type_description
    "dates"
  end

  def value_hint
    "Example of valid date: 1/25/2013."
  end

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		validated_value = {}
    validated_value[:date_from] = check_date_format(parse_date_from(value))
    validated_value[:date_to] = check_date_format(parse_date_to(value))
    validated_value
	end

	def apply_format_save_validation(value, use_codes_instead_of_es_codes, collection, site = nil)
		value.blank? ? nil : check_date_format(value)
	end

	private

	def check_date_format(value)
    # Convert to mm/dd/YYYY if the value is already an iso8601 string
    begin
      mdy_array = *value.split('/')
      mdy_value = [mdy_array[2], mdy_array[0], mdy_array[1]].map(&:to_i)
      value = Site.iso_string_to_mdy(value) unless Date.valid_date? *mdy_value
      Site.format_date_iso_string(Site.parse_date(value))
    rescue (raise "Invalid date value in field #{code}")
    end
  end

  def parse_date_from(value)
    match = (value.match /(.*),/)
    if match.nil?
      raise "Invalid date value in field #{code}"
    end
    match.captures[0]
  end

  def parse_date_to(value)
    match = (value.match /,(.*)/)
    if match.nil?
      raise "Invalid date value in field #{code}"
    end
    match.captures[0]
  end


end