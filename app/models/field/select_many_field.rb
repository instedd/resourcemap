class Field::SelectManyField < Field

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		check_presence_of_value(value)
		check_option_exists(value, use_codes_instead_of_es_codes)
	end

	def apply_format_save_validation(value, use_codes_instead_of_es_codes, collection)
		value.blank? ? nil : decode_select_many_options(value, use_codes_instead_of_es_codes)
	end

	private

  def check_option_exists(value, use_codes_instead_of_es_codes)
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

	def decode_select_many_options(options, use_codes_instead_of_es_codes)
    if options.kind_of?(Array)
      option_list = options
    else
      option_list = options.to_s.split(%r{\s*,\s*})
    end
    value_ids = []
    option_list.each do |value|
      value_id = check_option_exists(value, use_codes_instead_of_es_codes)
      value_ids << value_id
    end
    value_ids
  end


end