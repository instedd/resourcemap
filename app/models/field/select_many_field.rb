class Field::SelectManyField < Field

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		check_precense_of_value(value)
		decode_option(value, use_codes_instead_of_es_codes)
	end

	def apply_format_update_validation(value, use_codes_instead_of_es_codes, collection)
		value.blank? ? nil : decode_select_many_options(value, use_codes_instead_of_es_codes)
	end

end