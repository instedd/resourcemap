class Field::IdentifierField < Field
  IdentifierKinds = ['Normal', 'Luhn']

  def value_type_description
    "identifier values"
  end

  def value_hint
    format_implementation.value_hint
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

    @format_implementation = "Field::IdentifierField::#{format}".constantize.new(self)
  end

  def cache_for_read
    format_implementation.cache_for_read
  end

  def disable_cache_for_read
    format_implementation.disable_cache_for_read
  end
end

class Field::IdentifierField::FormatImplementation

  def existing_values
    if @cache_for_read && @existing_values_in_cache
      return @existing_values_in_cache
    end

    search = @field.collection.new_search
    property_code = "properties.#{@field.es_code}"
    search.select_fields(["id",property_code])
    search.unlimited
    search.apply_queries
    existing = search.results.results.map{ |item| item["fields"]}.index_by{|e| e[property_code]}

    if @cache_for_read
      @existing_values_in_cache = existing
    end

    existing
  end


  def cache_for_read
    @cache_for_read = true
  end

  def disable_cache_for_read
    @cache_for_read = false
  end

  def initialize(field)
    @field = field
  end

  def valid_value?(value, existing_site)
    if existing_values[value]
      # If the value already exists in the collection, the value will be invalid
      # Unless this is an update to an update an existing site with the same value
      raise "the value already exists in the collection" unless (existing_site && (existing_values[value]["id"] == existing_site.id))    end
    true
  end

  def has_luhn_format?()
    false
  end

  def decode(value)
    value
  end

  def default_value_for_create(collection)
    nil
  end

  def value_hint
    nil
  end

end

class Field::IdentifierField::Normal < Field::IdentifierField::FormatImplementation

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

class Field::IdentifierField::Luhn < Field::IdentifierField::FormatImplementation

  def error_description_for_invalid_values(exception)
    "are not valid for the type luhn identifier: #{exception}"
  end

  def has_luhn_format?()
    true
  end

  def value_hint
    "Luhn identifiers must be in this format: nnnnnn-n (where 'n' is a number), must be unique and pass the luhn check."
  end

  def decode(value)
    value
  end

  def valid_value?(value, site)

    unless value =~ /(\d\d\d\d\d\d)\-(\d)/
      raise "the value must be in this format: nnnnnn-n (where 'n' is a number)"
    end

    verifier = compute_luhn_verifier($1)
    if verifier != $2.to_i
      raise "the value failed the luhn check"
    end

    super
    true
  end

  def compute_luhn_verifier(str)
    n = str.length - 1
    even = false
    sum = 0
    while n >= 0
      digit = str[n].to_i

      if even
        if digit < 5
          sum += digit
        else
          sum += 1 + (digit - 5) * 2
        end
      else
        sum += digit
      end

      even = !even

      n -= 1
    end

    (10 - sum) % 10
  end

  def largest_existing_luhn_value_in_this_field(collection)
    # Find largest existing value in ES
    field_es_code = "properties.#{@field.es_code}"
    search = collection.new_search
    search.unlimited
    search.field_exists(field_es_code)
    search.sort field_es_code, false
    search.limit(1)

    site_with_last_luhn_value = search.results.results

    if !site_with_last_luhn_value.empty?
      site_with_last_luhn_value.first["_source"]["properties"][@field.es_code]
    else
      # Not found
      nil
    end
  end

  def default_value_for_create(collection)
    last_luhn_value = largest_existing_luhn_value_in_this_field(collection)
    return "100000-9" unless last_luhn_value
    next_luhn(last_luhn_value)
  end

  def next_luhn(last_luhn_value)
    # We calculate the next value using just the found largest
    # This may become a problem if a user enters manually a really large luhn number
    # In this case we may search for holes, but we will take care of that case when it happens
    # Doing it now will cause a loooot of (unnecessary) processing in memory
    without_validation_digit = last_luhn_value[0 ... 6].to_i
    "#{without_validation_digit + 1}-#{compute_luhn_verifier((without_validation_digit + 1).to_s)}"
  end
end
