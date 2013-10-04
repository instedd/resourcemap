class Field::IdentifierFields::NormalField < Field::IdentifierFields::FormatImplementation

  def error_description_for_invalid_values(exception)
    "are not valid for the type identifier: #{exception}"
  end

  def valid_value?(value, site)
    super
    true
  end

  def value_hint
    "Identifiers must be unique."
  end

end
