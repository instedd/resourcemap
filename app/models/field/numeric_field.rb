class Field::NumericField < Field
  def value_type_description
    "numeric values"
  end

  def value_hint
    "Values must be integers."
  end

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		check_presence_of_value(value)
    valid_value?(value)
    standarize(value)
	end

  def standarize(value)
    if allow_decimals?
      value.to_f
    else
      value.to_i
    end
  end

  def decode(value)
    if allow_decimals? 
      raise allows_decimals_message unless value.real?
      Float(value)
    else
      raise not_allow_decimals_message unless value.integer?
      Integer(value)
    end
  end

  def valid_value?(value, site = nil)
    if allow_decimals?
      raise allows_decimals_message unless value.real?
    else
      raise not_allow_decimals_message if !value.integer? && value.real?
      raise invalid_field_message unless value.integer?
    end
    true
  end

  private

  def invalid_field_message()
    "Invalid numeric value in field #{code}"
  end

  def allows_decimals_message()
    "#{invalid_field_message}. This numeric field is configured to allow decimal values."
  end

  def not_allow_decimals_message()
    "#{invalid_field_message}. This numeric field is configured not to allow decimal values."
  end

end
