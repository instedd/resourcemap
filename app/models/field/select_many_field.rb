class Field::SelectManyField < Field
  def value_type_description
    "option values"
  end

  def error_description_for_invalid_values(exception)
    "don't match any existing option"
  end

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		check_presence_of_value(value)
		query_value(value, use_codes_instead_of_es_codes)
	end

  def standarize(value)
    if value.kind_of?(Array)
      option_list = value
    else
      option_list = value.to_s.split(%r{\s*,\s*})
    end
    option_list.map(&:to_i)
  end

  def decode(option_values)
    if option_values.kind_of?(Array)
      option_values = option_values
    else
      option_values = option_values.to_s.split(%r{\s*,\s*})
    end
    value_ids = []
    option_values.each do |value|
      value_id = decode_option(value)
      value_ids << value_id
    end
    value_ids
  end

  def valid_value?(option_codes, site = nil)
    if option_codes.kind_of?(Array)
      option_codes_list = option_codes
    else
      option_codes_list = option_codes.to_s.split(%r{\s*,\s*})
    end
    option_codes_list.each do |option|
      check_option_exists(option)
    end
  end

	private

  # TODO: Integrate with decode used in update
  def query_value(value, use_codes_instead_of_es_codes)
    value_id = nil
    if use_codes_instead_of_es_codes
      config['options'].each do |option|
        value_id = option['id'] if option['label'] == value || option['code'] == value
      end
    else
      config['options'].each do |option|
        value_id = option['id'] if option['id'].to_s == value.to_s
      end
    end
    raise "Invalid option in field #{code}" if value_id.nil?
    value_id
  end

  def invalid_field_message(value)
    "Invalid option '#{value}' in field #{code}"
  end

  def decode_option(value)
    value_id = nil
    config['options'].each do |option|
      value_id = option['id'] if option['label'] == value || option['code'] == value
    end

    if value_id.nil?
      raise invalid_field_message(value)
    else
      value_id
    end
  end

  def check_option_exists(value)
    exists = false
    config['options'].each do |option|
      exists = true if option['id'].to_s == value.to_s
    end
    raise invalid_field_message(value) if !exists
    exists
  end

end
