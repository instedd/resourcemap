class Field::IdentifierField < Field
  IdentifierKinds = ['Normal', 'Luhn']

  def apply_format_update_validation(*args)
    format_implementation.apply_format_update_validation(*args)
  end

  def format_implementation
    "Field::IdentifierField::#{config['format'] || 'Normal'}".constantize.new
  end
end

class Field::IdentifierField::FormatImplementation
  def apply_format_update_validation(value, use_codes_instead_of_es_codes, collection)
    value.blank? ? nil : value
  end
end

class Field::IdentifierField::Normal < Field::IdentifierField::FormatImplementation
end

class Field::IdentifierField::Luhn < Field::IdentifierField::FormatImplementation
  def apply_format_update_validation(value, use_codes_instead_of_es_codes, collection)
    return nil if value.blank?

    unless value =~ /(\d\d\d\d\d\d)\-(\d)/
      raise "the value must be in this format: nnnnnn-n (where 'n' is a number)"
    end

    verifier = compute_lunh_verfier($1)
    if verifier != $2.to_i
      raise "the value failed the lunh check"
    end

    value
  end

  def compute_lunh_verfier(str)
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
end
