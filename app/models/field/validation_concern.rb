module Field::ValidationConcern
  extend ActiveSupport::Concern

  def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
    check_presence_of_value(value)
    value
  end

  def apply_format_save_validation(value, use_codes_instead_of_es_codes, collection)
    value.blank? ? nil : value
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
