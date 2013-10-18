class Field::HierarchyField < Field
  def value_type_description
    "values that can be found in the defined hierarchy"
  end

  def value_hint
    "Some valid values for this hierarchy are: #{hierarchy_options_id_samples}."
  end

  def error_description_for_invalid_values(exception)
    "don't exist in the corresponding hierarchy"
  end

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		check_presence_of_value(value)
		decode_hierarchy_option(value, use_codes_instead_of_es_codes)
	end

  def api_value(value)
    value if find_hierarchy_option_by_id(value)
  end

  def human_value(value)
    find_hierarchy_value(value)
  end

  def hierarchy_to_csv
    CSV.generate do |csv|
      header = ['ID', 'ParentID', 'ItemName']
      csv << header

      hierarchy_options.each do |option|
        csv << ["#{option[:id]}", "#{option[:parent_id]}", "#{option[:name]}"]
      end
    end
  end

  def decode(hierarchy_id_or_name)
    if find_hierarchy_option_by_id(hierarchy_id_or_name)
      hierarchy_id_or_name
    else
      hierarchy_code = find_hierarchy_id_by_name(hierarchy_id_or_name)
      raise invalid_field_message(hierarchy_id_or_name) if hierarchy_code.blank?
      raise "Multiple hierarchy option '#{hierarchy_id_or_name}' in field '#{code}'" if hierarchy_code.size > 1

      hierarchy_code.first
    end
  end

  def invalid_field_message(hierarchy_code = nil)
    "Invalid hierarchy option '#{hierarchy_code}' in field '#{code}'"
  end

  def valid_value?(hierarchy_code, site = nil)

    if find_hierarchy_option_by_id(hierarchy_code)
      true
    else
      raise invalid_field_message(hierarchy_code)
    end
  end

  def ascendants_of_in_hierarchy(node_id_or_name)
    begin
      valid_value?(node_id_or_name)
      node_ids = [node_id_or_name]
    rescue
      node_ids = find_hierarchy_id_by_name(node_id_or_name)
      raise invalid_field_message(node_id_or_name) if node_ids.blank?
    end

    options = []
    node_ids.each do |node_id|
      while (!node_id.blank?)
        option = find_hierarchy_option_by_id(node_id)
        options << { id: option[:id], name: option[:name], type: option[:type]}
        node_id = option[:parent_id]
      end
    end

    options
  end

  def ascendants_with_type(node_id_or_name, type)
    ascendants = ascendants_of_in_hierarchy(node_id_or_name)
    res = ascendants.find{|option| option[:type] == type }
    res
  end

	def descendants_of_in_hierarchy(parent_id_or_name)
    begin
      valid_value?(parent_id_or_name)
      parent_ids = [parent_id_or_name]
    rescue
      parent_ids = find_hierarchy_id_by_name(parent_id_or_name)
      raise invalid_field_message(parent_id_or_name) if parent_ids.blank?
    end
    options = []
    parent_ids.each do |parent_id|
      add_option_to_options options, find_hierarchy_item_by_id(parent_id)
    end

    options.map { |item| item[:id] }
  end

  def cache_for_read
    @cache_for_read = true
  end

  def disable_cache_for_read
    @cache_for_read = false
  end

  def hierarchy_options_codes
    hierarchy_options.map {|option| option[:id].to_s}
  end

  def hierarchy_options_ids
    hierarchy_options.map {|option| option[:id]}
  end

  def hierarchy_options_id_samples
    hierarchy_options_ids.take(3).join(", ")
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
      @options_by_name ||= hierarchy_options.each_with_object({}) do |opt, hash|
        if hash[opt[:name]]
          hash[opt[:name]] << opt[:id]
        else
          hash[opt[:name]] = [opt[:id]]
        end
      end
      return @options_by_name[value]
    end

    options = hierarchy_options.select { |opt| opt[:name] == value }
    unless options.empty?
      options.map { |option| option[:id]}
    else
      nil
    end
  end

  def find_hierarchy_name_by_id(value)
    option = find_hierarchy_option_by_id(value)
    option[:name] if option
  end

  def find_hierarchy_option_by_id(value)
    if @cache_for_read
      @options_by_id ||= hierarchy_options.each_with_object({}) { |opt, hash| hash[opt[:id]] = opt[:name] }
      return @options_by_id[value]
    end

    hierarchy_options.find { |opt| opt[:id].to_s == value.to_s }
  end

	private

  def add_option_to_options(options, option, parent_id = '')
    this_option = { id: option['id'], name: option['name'], parent_id: parent_id}
    if option['type']
      this_option[:type] = option['type']
    end

    options << this_option
    if option['sub']
      option['sub'].each do |sub_option|
        add_option_to_options(options, sub_option, option['id'])
      end
    end
  end

  #TODO: deprecate
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

  # TODO: Integrate with decode used in update
  def decode_hierarchy_option(array_value, use_codes_instead_of_es_codes)
    if !array_value.kind_of?(Array)
      array_value = [array_value]
    end
    value_ids = []
    array_value.each do |value|
      value_id = check_option_exists(value, use_codes_instead_of_es_codes)
      value_ids << value_id
    end
    value_ids.flatten
  end

  def check_option_exists(value, use_codes_instead_of_es_codes)
    value_id = nil
    if use_codes_instead_of_es_codes
      value_id = find_hierarchy_id_by_name(value)
      value_id = value if value_id.blank? && !find_hierarchy_name_by_id(value).nil?
    else
      value_id = value unless !hierarchy_options_codes.include? value.to_s
    end
    raise "Invalid hierarchy option in field #{code}" if value_id.nil?
    value_id
  end
end
