module Field::ValidationConcern
  extend ActiveSupport::Concern

  def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
    check_presence_of_value(value)
    value
  end

  def apply_format_and_validate(value, use_codes_instead_of_es_codes, collection, site = nil)
    decoded_value = value.blank? ? nil : decode(value)  
    if decoded_value 
      standarize(decoded_value) if valid_value?(decoded_value, site)
    else
      decoded_value
    end
  end

  def decode(value)
    value
  end

  def valid_value?(value, site = nil)
    true
  end

  def standarize(value)
    value
  end

  def decode_fred(value)
    decode(value)
  end

  module ClassMethods
    def yes?(value)
      value == true || value == 1 || !!(value =~ /\A(yes|true|1)\Z/i)
    end
  end

  private

  def check_presence_of_value(value)
    raise "Missing #{code} value" if value.blank?
  end


end
