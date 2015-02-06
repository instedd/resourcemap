class Field::YesNoField < Field

  def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
    Field.yes?(value)
  end

  def decode(value)
    Field.yes?(value)
  end

  def api_value(value)
    Field.yes?(value)
  end

  def default_value_for_create(collection)
    false
  end

  def csv_values(value, human = false)
    [Field.yes?(value) ? 'yes' : 'no']
  end

  def default_value_for_update
    if config && Field.yes?(config['auto_reset'])
      false
    else
      nil
    end
  end

  def standardize(value)
    value == true || value == "true"
  end
end
