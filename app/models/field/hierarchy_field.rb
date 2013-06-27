class Field::HierarchyField < Field
  def value_type_description
    "values that can be found in the defined hierarchy"
  end

  def value_hint
    "Some valid values for this hierarchy are: #{hierarchy_options_names_samples}."
  end

  def error_description_for_invalid_values(exception)
    "don't exist in the corresponding hierarchy"
  end

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		check_presence_of_value(value)
		decode_hierarchy_option(value, use_codes_instead_of_es_codes)
	end

	def apply_format_save_validation(value, use_codes_instead_of_es_codes, collection)
    value.blank? ? nil : check_option_exists(value, use_codes_instead_of_es_codes)
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

  def cache_for_read
    @cache_for_read = true
  end

  def hierarchy_options_codes
    hierarchy_options.map {|option| option[:id]}
  end

  def hierarchy_options_names
    hierarchy_options.map {|option| option[:name]}
  end

  def hierarchy_options_names_samples
    hierarchy_options_names.take(3).join(", ")
  end

  def hierarchy_options
    if @cache_for_read && @options_in_cache
      return @options_in_cache
    end

    options = []
    config['hierarchy'].each do |option|
      add_option_to_options(options, option)
    end

    if @cache_for_read
      @options_in_cache = options
    end

    options
  end

  def find_hierarchy_id_by_name(value)
    if @cache_for_read
      @options_by_name ||= hierarchy_options.each_with_object({}) { |opt, hash| hash[opt[:name]] = opt[:id] }
      return @options_by_name[value]
    end

    option = hierarchy_options.find { |opt| opt[:name] == value }
    option[:id] if option
  end

  def find_hierarchy_name_by_id(value)
    if @cache_for_read
      @options_by_id ||= hierarchy_options.each_with_object({}) { |opt, hash| hash[opt[:id]] = opt[:name] }
      return @options_by_id[value]
    end

    option = hierarchy_options.find { |opt| opt[:id] == value }
    option[:name] if option
  end

	private

  def check_option_exists(value, use_codes_instead_of_es_codes)
    value_id = nil
    if use_codes_instead_of_es_codes
      value_id = find_hierarchy_id_by_name(value)
      value_id = value if value_id.nil? && !find_hierarchy_name_by_id(value).nil?
    else
      value_id = value unless !hierarchy_options_codes.map{|o|o.to_s}.include? value.to_s
    end
    raise "Invalid hierarchy option in field #{code}" if value_id.nil?
    value_id
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

end