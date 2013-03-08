module Field::ValidationConcern
  extend ActiveSupport::Concern

  def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
    check_precense_of_value(value)
    value
  end

  def apply_format_update_validation(value, use_codes_instead_of_es_codes, collection)
    value.blank? ? nil : value
  end

  module ClassMethods
    def yes?(value)
      value == true || value == 1 || !!(value =~ /\A(yes|true|1)\Z/i)
    end
  end

  private

  def check_precense_of_value(value)
    raise "Missing #{code} value" if value.blank?
  end

  def decode_select_many_options(option_string, use_codes_instead_of_es_codes)
    if option_string.kind_of?(Array)
      option_list = option_string
    else
      option_list = option_string.split(%r{\s*,\s*})
    end
    value_ids = []
    option_list.each do |value|
      value_id = check_option_exists(value, use_codes_instead_of_es_codes)
      value_ids << value_id
    end
    value_ids
  end

  def check_option_exists(value, use_codes_instead_of_es_codes)
    value_id = nil
    if kind == 'hierarchy'
      if use_codes_instead_of_es_codes
        value_id = find_hierarchy_id_by_name(value)
      else
        value_id = value unless !hierarchy_options_codes.include? value
      end
    elsif kind == 'select_many'
      if use_codes_instead_of_es_codes
        config['options'].each do |option|
          value_id = option['id'] if option['label'] == value || option['code'] == value
        end
      else
        value_id = value if config["options"].any?{|opt| opt["id"].to_s == value.to_s}
      end
    elsif kind == 'select_one'
      if use_codes_instead_of_es_codes
        config['options'].each do |option|
          value_id = option['id'] if option['label'] == value || option['code'] == value
        end
      else
        value_id = value if config["options"].any?{|opt| opt["id"].to_s == value.to_s}
      end
    end
    raise "Invalid option in #{code} field" if value_id.nil?
    value_id
  end

  def decode_option(value, use_codes_instead_of_es_codes)
    check_option_exists(value, use_codes_instead_of_es_codes)
  end

end
