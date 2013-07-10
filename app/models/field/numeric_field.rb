class Field::NumericField < Field
  def value_type_description
    "numeric values"
  end

  def value_hint
    "Values must be integers."
  end

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		check_presence_of_value(value)
    check_valid_numeric_value(value)
	end

	def apply_format_and_validate(value, use_codes_instead_of_es_codes, collection, site = nil)
    value.blank? ? nil : check_valid_numeric_value(value)
	end

	private

	def check_valid_numeric_value(value)
    feedback = "Invalid numeric value in field #{code}"
    about_decimals = "This numeric field is configured not to allow decimal values."

    if allow_decimals?
      raise "#{feedback}. #{about_decimals}" unless value.real?
      Float(value)
    else
      raise "#{feedback}. #{about_decimals}" if !value.integer? && value.real?
      raise feedback unless value.integer?
      Integer(value)
    end
  end

end
