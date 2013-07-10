class Field::IdentifierField < Field
  IdentifierKinds = ['Normal', 'Luhn']

  def value_type_description
    "identifier values"
  end

  def value_hint
    format_implementation.value_hint
  end

  def apply_format_and_validate(*args)
    format_implementation.apply_format_and_validate(*args)
  end

  def default_value_for_create(collection)
    format_implementation.default_value_for_create(collection)
  end

  def error_description_for_invalid_values(exception)
    format_implementation.error_description_for_invalid_values(exception)
  end

  def format_implementation
    "Field::IdentifierField::#{config['format'] || 'Normal'}".constantize.new(self)
  end
end

class Field::IdentifierField::FormatImplementation
  def initialize(field)
    @field = field
  end

  def apply_format_and_validate(value, use_codes_instead_of_es_codes, collection, site = nil)
    value.blank? ? nil : value
  end

  def default_value_for_create(collection)
    nil
  end

  def value_hint
    nil
  end

  def error_description_for_invalid_values(exception)
    "are not valid for the type identifier"
  end
end

class Field::IdentifierField::Normal < Field::IdentifierField::FormatImplementation
end

class Field::IdentifierField::Luhn < Field::IdentifierField::FormatImplementation
  def error_description_for_invalid_values(exception)
    "are not valid for the type luhn identifier: #{exception}"
  end

  def value_hint
    "Luhn identifiers must be in this format: nnnnnn-n (where 'n' is a number), must be unique and pass the luhn check."
  end


  def apply_format_and_validate(value, use_codes_instead_of_es_codes, collection, site = nil)
    if value.blank?
      return nil
    end

    unless value =~ /(\d\d\d\d\d\d)\-(\d)/
      raise "the value must be in this format: nnnnnn-n (where 'n' is a number)"
    end

    verifier = compute_luhn_verifier($1)
    if verifier != $2.to_i
      raise "the value failed the luhn check"
    end

    field_es_code = "properties.#{@field.es_code}"
    search = collection.new_search
    search.select_fields [field_es_code]
    search.eq @field, value
    results = search.results
    if results.length == 1
      if site && results.results.any? { |r| r["_id"].to_s == site.id.to_s }
        return value
      end
      raise "the value already exists in the collection"
    end

    value
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

    10 - sum % 10
  end

  def default_value_for_create(collection)
    field_es_code = "properties.#{@field.es_code}"
    search = collection.new_search
    search.select_fields [field_es_code]
    search.sort field_es_code, true
    results = search.results

    return "100000-9" if results.empty?

    last = nil

    results.results.each do |result|
      result = result["fields"]
      next unless result
      value = result[field_es_code]
      next unless value

      value = value[0 ... 6].to_i
      if last && value - last > 1
        break
      end
      last = value
    end

    "#{last + 1}-#{compute_luhn_verifier((last + 1).to_s)}"
  end
end
