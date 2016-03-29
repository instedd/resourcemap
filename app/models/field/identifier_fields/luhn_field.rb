
class Field::IdentifierFields::LuhnField < Field::IdentifierFields::FormatImplementation

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

    unless value =~ /\A(\d\d\d\d\d\d)\-(\d)\Z/
      raise "The value must be in this format: nnnnnn-n (where 'n' is a number)"
    end

    verifier = compute_luhn_verifier($1)
    if verifier != $2.to_i
      raise "Invalid Luhn check digit"
    end

    super
    true
  end

  def compute_luhn_verifier(str)
    # Algorithm: http://en.wikipedia.org/wiki/Luhn_algorithm
    # Verifier: http://www.ee.unb.ca/cgi-bin/tervo/luhn.pl
    n = str.length - 1
    even = true
    sum = 0
    while n >= 0
      digit = str[n].to_i

      if even
        if digit < 5
          sum += digit * 2
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
    search.field_exists(field_es_code)
    search.sort field_es_code, false
    search.offset(0)
    search.limit(1)
    search.show_deleted

    site_with_last_luhn_value = search.results

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
    next_number = without_validation_digit + 1
    next_number = "%06d" % next_number
    "#{next_number}-#{compute_luhn_verifier((next_number).to_s)}"
  end
end
