class Field::ImageGalleryField < Field
  ID = 'id'.freeze
  LABEL = 'label'.freeze
  CODE = 'code'.freeze

  def value_type_description
    # FIXME: check what description fits best
    "a gallery of images to show"
  end

  def error_description_for_invalid_values(exception)
    # FIXME: check
    "don't match any existing option"
  end

  def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
    # FIXME
    check_presence_of_value(value)
    query_value(value, use_codes_instead_of_es_codes)
  end

  def cache_for_read
    @cache_for_read = true
  end

  def disable_cache_for_read
    @cache_for_read = false
  end

  def cached_options
    cached :@options do
      config['options']
    end
  end

  def config_option_by_id(val)
    options = cached :@options_by_id do
      Hash[config['options'].map { |o| [o[ID], o] }]
    end
    options[val]
  end

  def api_value(value)
    if value.is_a? Array
      return value.map do |val|
        option = config_option_by_id(val)
        option ? option[CODE] : val
      end
    else
      return value
    end
  end

  def human_value(value)
    if value.is_a? Array
      return value.map do |val|
        option = config_option_by_id(val)
        option ? option[LABEL] : val
      end.join ', '
    else
      return value
    end
  end

  def standardize(value)
    if value.kind_of?(Array)
      option_list = value
    else
      option_list = value.to_s.split(%r{\s*,\s*})
    end
    option_list.map(&:to_i)
  end

  def decode(option_values)
    if option_values.kind_of?(Array)
      option_values = option_values
    else
      option_values = option_values.to_s.split(%r{\s*,\s*})
    end
    value_ids = []
    option_values.each do |value|
      value_id = decode_option(value)
      value_ids << value_id
    end
    value_ids
  end

  def valid_value?(option_codes, site = nil)
    if option_codes.kind_of?(Array)
      option_codes_list = option_codes
    else
      option_codes_list = option_codes.to_s.split(%r{\s*,\s*})
    end
    option_codes_list.each do |option|
      check_option_exists(option)
    end
  end

  def select_kind?
    true
  end

	private

  # TODO: Integrate with decode used in update
  def query_value(value, use_codes_instead_of_es_codes)
    value_id = nil
    if use_codes_instead_of_es_codes
      cached_options.each do |option|
        value_id = option[ID] if option[LABEL] == value || option[CODE] == value
      end
    else
      cached_options.each do |option|
        value_id = option[ID] if option[ID].to_s == value.to_s
      end
    end
    raise "Invalid option in field #{code}" if value_id.nil?
    value_id
  end

  def invalid_field_message(value)
    "Invalid option '#{value}' in field #{code}"
  end

  def decode_option(value)
    value_id = nil
    cached_options.each do |option|
      value_id = option[ID] if option[LABEL].downcase == value.downcase || option[CODE].downcase == value.downcase
    end

    if value_id.nil?
      raise invalid_field_message(value)
    else
      value_id
    end
  end

  def check_option_exists(value)
    exists = false
    cached_options.each do |option|
      exists = true if option[ID].to_s == value.to_s
    end
    raise invalid_field_message(value) if !exists
    exists
  end

end
