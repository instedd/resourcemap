class Field::SelectOneField < Field

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		return nil unless value.present?

		decode_option(value, use_codes_instead_of_es_codes)
	end

	def apply_format_update_validation(value, use_codes_instead_of_es_codes, collection)
		value.blank? ? nil : decode_option(value, use_codes_instead_of_es_codes)
	end

	private

	def decode_option(value, use_codes_instead_of_es_codes)
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

end