class Field::YesNoField < Field

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		check_presence_of_value(value)
		Field.yes?(value)
	end

	def apply_format_and_validate(value, use_codes_instead_of_es_codes, collection, site = nil)
		(value == nil || value == '') ? nil : Field.yes?(value)
	end

end
