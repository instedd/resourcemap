class Field::SelectOneField < Field

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		check_precense_of_value(value)
		decode_option(value, use_codes_instead_of_es_codes)
	end

	def apply_format_update_validation(value, use_codes_instead_of_es_codes, collection)
		value.blank? ? nil : check_option_exists(value, use_codes_instead_of_es_codes)
	end

end