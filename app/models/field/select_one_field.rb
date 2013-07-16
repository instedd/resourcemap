class Field::SelectOneField < Field
  def value_type_description
    "option values"
  end

  def error_description_for_invalid_values(exception)
    "don't match any existing option"
  end

  def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
    return nil unless value.present?
    query_value(value, use_codes_instead_of_es_codes)
  end

  def decode(option_label_or_code)
    decode_option(option_label_or_code)
  end

  def standarize(value)
    value.to_i
  end

  def valid_value?(option_code, site=nil)
    if @cache_for_read 
      raise invalid_field_message unless @options_by_id_in_cache.values.include?(option_code)
    else
      check_option_exists(option_code)
    end
  end

  def cache_for_read
    @cache_for_read = true
  end

  private
  
  # TODO: Integrate with decode used in update
  def query_value(value, use_codes_instead_of_es_codes)
    if @cache_for_read && !@options_by_code_or_label_in_cache
      prepare_cache_for_read
    end

    value_id = nil
    if use_codes_instead_of_es_codes
      if @cache_for_read
        value_id = @options_by_code_or_label_in_cache[value.to_s]
      else
        config['options'].each do |option|
          value_id = option['id'] if option['label'] == value || option['code'] == value
        end
      end
    else
      if @cache_for_read
        value_id = @options_by_id_in_cache[value.to_s]
      else
        config['options'].each do |option|
          value_id = option['id'] if option['id'].to_s == value.to_s
        end
      end
    end
    raise "Invalid option in field #{code}" if value_id.nil?
    value_id
  end

  def check_option_exists(value)
    exists = false
    config['options'].each do |option|
      exists = true if option['id'].to_s == value.to_s
    end
    raise invalid_field_message if !exists
    exists
  end

  def invalid_field_message()
    "Invalid option in field #{code}"
  end

  def decode_option(value)
    if @cache_for_read && !@options_by_code_or_label_in_cache
      prepare_cache_for_read
    end
    value_id = nil
    if @cache_for_read
      value_id = @options_by_code_or_label_in_cache[value.to_s]
    else
      config['options'].each do |option|
        value_id = option['id'] if option['label'] == value || option['code'] == value
      end
    end
    if value_id.nil?
      raise invalid_field_message
    else
      value_id
    end
  end

  def prepare_cache_for_read
    @options_by_code_or_label_in_cache = {}
    @options_by_id_in_cache = {}

    config['options'].each do |option|
      @options_by_code_or_label_in_cache[option['code'].to_s] = option['id']
      @options_by_code_or_label_in_cache[option['label'].to_s] = option['id']
      @options_by_id_in_cache[option['id'].to_s] = option['id']
    end
  end

end
