class Field::IdentifierField < Field
  IdentifierKinds = ['Normal', 'Luhn']

  def value_type_description
    "identifier values"
  end

  def value_hint
    format_implementation.value_hint
  end

  def existing_values
    format_implementation.existing_values
  end

  def valid_value?(*args)
    format_implementation.valid_value?(*args)
  end

  def decode(*args)
    format_implementation.decode(*args)
  end

  def default_value_for_create(collection)
    format_implementation.default_value_for_create(collection)
  end

  def error_description_for_invalid_values(exception)
    format_implementation.error_description_for_invalid_values(exception)
  end

  def has_luhn_format?
    format_implementation.has_luhn_format?
  end

  def format_implementation
    if @format_implementation
      return @format_implementation
    end

    format = if config && config['format']
      config['format']
    else
      'Normal'
    end

    @format_implementation = "Field::IdentifierFields::#{format}Field".constantize.new(self)
  end

  def cache_for_read
    format_implementation.cache_for_read
  end

  def disable_cache_for_read
    format_implementation.disable_cache_for_read
  end
end
