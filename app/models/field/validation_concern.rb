module Field::ValidationConcern
  extend ActiveSupport::Concern

  def apply_format_validation(value, use_codes_instead_of_es_codes)
    check_precense_of_value(value)
    if kind == 'numeric'
      validated_value = check_valid_numeric_value(value)
    elsif kind == 'date'
      validated_value = {}
      validated_value[:date_from] = check_date_format(parse_date_from(value))
      validated_value[:date_to] = check_date_format(parse_date_to(value))
    elsif kind == 'hierarchy'
      validated_value = decode_hierarchy_option(value, use_codes_instead_of_es_codes)
    elsif select_kind?
      validated_value = decode_option(value, use_codes_instead_of_es_codes)
    else
      validated_value = value
    end
    validated_value
  end

  def descendants_of_in_hierarchy(parent_id, use_codes_instead_of_es_codes)
    parent_id = check_option_exists parent_id, use_codes_instead_of_es_codes
    options = []
    add_option_to_options options, find_hierarchy_item_by_id(parent_id)
    if use_codes_instead_of_es_codes
      options.map { |item| item[:name] }
    else
      options.map { |item| item[:id] }
    end
  end

  private

  def check_precense_of_value(value)
    raise "Missing #{code} value" if value.blank?
  end

  def check_valid_numeric_value(value)
    raise "Invalid numeric value in #{code} param" unless value.integer?
    value
  end

  def integer?(string)
    true if Integer(string) rescue false
  end

  def check_date_format(value)
    Time.strptime(value, '%m/%d/%Y') rescue (raise "Invalid date value in #{code} param")
  end

  def parse_date_from(value)
    match = (value.match /(.*),/)
    match.captures[0] rescue (raise "Invalid date value in #{code} param")
  end

  def parse_date_to(value)
    match = (value.match /,(.*)/)
    match.captures[0]
  end

  def decode_hierarchy_option(array_value, use_codes_instead_of_es_codes)
    value_ids = []
    array_value.each do |value|
      value_id = check_option_exists(value, use_codes_instead_of_es_codes)
      value_ids << value_id
    end
    value_ids
  end

  def find_hierarchy_item_by_id(id, start_at = config['hierarchy'])
    start_at.each do |item|
      return item if item['id'] == id
      return find_hierarchy_item_by_id(id, item['sub']) if item.has_key? 'sub'
    end
    raise "No item '#{id}' found in hierarchy"
  end

  def check_option_exists(value, use_codes_instead_of_es_codes)
    value_id = nil
    if kind == 'hierarchy'
      if use_codes_instead_of_es_codes
        value_id = find_hierarchy_id_by_name(value)
      else
        value_id = value unless !hierarchy_options_codes.include? value
      end
    elsif select_kind?
      config['options'].each do |option|
        if use_codes_instead_of_es_codes
          value_id = option['id'] if option['label'] == value || option['code'] == value
        else
          value_id = value if config["options"].any?{|opt| opt["id"].to_s == value}
        end
      end
    end
    raise "Invalid option in #{code} param" if value_id.nil?
    value_id
  end

  def decode_option(value, use_codes_instead_of_es_codes)
    value_id = check_option_exists(value, use_codes_instead_of_es_codes)
    value_id
  end

end
