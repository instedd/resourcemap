module Field::ValidationConcern
  extend ActiveSupport::Concern

  def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
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

  def apply_format_update_validation(value, use_codes_instead_of_es_codes, collection)
    if value.blank?
      return nil
    elsif kind == 'numeric'
      validated_value = check_valid_numeric_value(value)
    elsif kind == 'date'
      validated_value = check_date_format(value)
    elsif kind == 'hierarchy'
      validated_value = check_option_exists(value, use_codes_instead_of_es_codes)
    elsif kind == 'select_many'
      validated_value = decode_select_many_options(value, use_codes_instead_of_es_codes)
    elsif kind == 'select_one'
      validated_value = check_option_exists(value, use_codes_instead_of_es_codes)
    elsif kind == 'email'
      validated_value = check_email_format(value)
    elsif kind == 'user'
      validated_value = check_user_exists(value, collection)
    elsif kind == 'site'
      validated_value = check_site_exists(value, collection)
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

  def check_email_format(value)
    regex = Regexp.new('^(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})$')
    if value.match(regex).nil?
      raise "Invalid email address in #{code} field"
    end
    value
  end

  def check_precense_of_value(value)
    raise "Missing #{code} value" if value.blank?
  end

  def check_valid_numeric_value(value)
    raise "Invalid numeric value in #{code} field" unless value.integer?
    Integer(value)
  end

  def check_date_format(value)
    Site.format_date_iso_string(Site.parse_date(value)) rescue (raise "Invalid date value in #{code} field")
  end

  def parse_date_from(value)
    match = (value.match /(.*),/)
    if match.nil?
      raise "Invalid date value in #{code} field"
    end
    match.captures[0]
  end

  def parse_date_to(value)
    match = (value.match /,(.*)/)
    if match.nil?
      raise "Invalid date value in #{code} field"
    end
    match.captures[0]
  end

  def decode_hierarchy_option(array_value, use_codes_instead_of_es_codes)
    if !array_value.kind_of?(Array)
      array_value = [array_value]
    end
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
      if item.has_key? 'sub'
        found = find_hierarchy_item_by_id(id, item['sub'])
        return found unless found.nil?
      end
    end
    nil
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
    value_id = check_option_exists(value, use_codes_instead_of_es_codes)
    value_id
  end

  def check_user_exists(user_email, collection)
    user_emails = collection.users.map {|u| u.email}

    if !user_emails.include? user_email
      raise "Non-existent user email address in #{code} field"
    end
    user_email
  end


  def check_site_exists(site_id, collection)
    site_ids = collection.sites.map{|s| s.id.to_s}

    if !site_ids.include? site_id.to_s
      raise "Non-existent site-id in #{code} field"
    end
    site_id
  end
end
