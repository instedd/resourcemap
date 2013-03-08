class Field::YesNoField < Field

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		check_precense_of_value(value)
		Field.yes?(value)
	end

	def apply_format_update_validation(value, use_codes_instead_of_es_codes, collection)
		value.blank? ? nil : Field.yes?(value)
	end

end