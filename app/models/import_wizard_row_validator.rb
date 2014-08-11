require 'ruby-prof'

class ImportWizardRowValidator
  def initialize(sites_errors, identifier_field, csv_columns, columns_spec, user, collection, collection_fields, csv_column_used_as_id, additional_data_file_path)
    @sites_errors = sites_errors
    @identifier_field = identifier_field
    @csv_columns = csv_columns
    @columns_spec = columns_spec
    @user = user
    @collection = collection
    @collection_fields = collection_fields
    @csv_column_used_as_id = csv_column_used_as_id
    @additional_data_file_path = additional_data_file_path
  end

  def validate_row
    #RubyProf.start

    @fields_by_id = @collection_fields.inject({}) {|dict, f| dict[f.id.to_s] = f; dict}
    @collection_sites_ids = @collection.sites.pluck(:id).map{|e| e.to_s}

    mapping_for_identifier_pivot = if @identifier_field then @identifier_field.existing_values else nil end

    @csv_columns.each_with_index do |csv_column, csv_column_number|
      column_spec = @columns_spec[csv_column_number]

      if column_spec[:use_as].to_s == 'new_field' && column_spec[:kind].to_s == 'hierarchy'
        @sites_errors[:hierarchy_field_found] = add_new_hierarchy_error(csv_column_number, @sites_errors[:hierarchy_field_found])
      elsif column_spec[:use_as].to_s == 'new_field' || column_spec[:use_as].to_s == 'existing_field'
        errors_for_column = validate_column(column_spec, csv_column, csv_column_number, mapping_for_identifier_pivot)
        @sites_errors[:data_errors].concat(errors_for_column)
      end
    end

    #prof_result = RubyProf.stop

    #File.open "#{::Rails.root}/tmp/prof_#{Time.now}", 'w' do |file|
    #  RubyProf::GraphHtmlPrinter.new(prof_result).print(file)
    #end

    @sites_errors
  end

  def validate_column(column_spec, csv_column, column_number, id_mapping)
    if column_spec[:use_as].to_sym == :existing_field      
      field = @fields_by_id[column_spec[:field_id].to_s]
    else
      field = new_field_for_column_spec(column_spec)
    end

    validated_csv_column = []

    # We need to store the maximum value in each luhn field in the csv in order to not search it again during the import
    max_luhn_value_in_csv = "0"

    # For identifier fields we build a hash of values to list of indices so we
    # can find out repretitions faster.
    values_to_indices = Hash.new { |h, k| h[k] = [] }
    repeated_values = []

    csv_column.each_with_index do |csv_field_value, row_index|
      begin
        existing_site_id = nil
        # load the site for the identifiers fields.
        # we need the site in order to validate the uniqueness of the luhn id value
        # The value should not be invlid if this same site has it
        if @csv_column_used_as_id && field.kind == 'identifier'
          if id_mapping && id_mapping[@csv_column_used_as_id[row_index]]
            # An identifier value was selected as pivot
            site_id = id_mapping[@csv_column_used_as_id[row_index]]["id"]
          else
            site_id = @csv_column_used_as_id[row_index]
          end
          existing_site_id = site_id if (site_id && !site_id.blank? && @collection_sites_ids.include?(site_id.to_s))
        end
        
        if field.kind == 'identifier'
          if !csv_field_value.blank?
            values_to_indices[csv_field_value] << row_index

            # Add this value to a shortlist of repeated values for faster error description generation
            repeated_values << csv_field_value if values_to_indices[csv_field_value].length == 2
          end
        end

        value = validate_column_value(column_spec, csv_field_value, field, existing_site_id)

        # Store the max value for Luhn generation
        if field.kind == 'identifier' && field.has_luhn_format?()
          max_luhn_value_in_csv = if (value && (value > max_luhn_value_in_csv)) then value else max_luhn_value_in_csv end
        end
      rescue => ex
        description = error_description_for_type(field, column_spec, ex)
        validated_csv_column << {description: description, row: row_index}
      end
    end

    process_repetitions values_to_indices, repeated_values, field, column_spec, validated_csv_column

    luhn_data = JSON.load(File.read(@additional_data_file_path))
    luhn_data[field.es_code] = max_luhn_value_in_csv if max_luhn_value_in_csv != "0"
    File.open(@additional_data_file_path, "wb") { |file| file << luhn_data.to_json }

    validated_columns_grouped = validated_csv_column.group_by{|e| e[:description]}
    validated_columns_grouped.map do |description, hash|
      {description: description, column: column_number, rows: hash.map { |e| e[:row] }, type: field.value_type_description, example: field.value_hint }
    end
  end

  def process_repetitions(values_to_indices, repeated_values, field, column_spec, validated_csv_column)
    repeated_values.each do |v|
      repetitions = values_to_indices[v]
      explanation = "the value is repeated in rows #{repetitions.map{|i|i+1}.to_sentence}"

      repetitions.each_with_index do |v, row_index| 
        description = error_description_for_type field, column_spec, explanation
        validated_csv_column << {description: description, row: row_index}
      end
    end
  end

  def validate_column_value(column_spec, field_value, field, site_id)
    if field.new_record?
      validate_format_value(column_spec, field_value, field)
    else
      field.apply_format_and_validate(field_value, true, @collection, site_id)
    end
  end

  def validate_format_value(column_spec, field_value, field)
    # Bypass some field validations
    case column_spec[:kind]
    when 'hierarchy'
      raise "Hierarchy fields can only be created via web in the Layers page"
    when 'select_one', 'select_many'
      # options will be created
      return field_value
    end

    field.apply_format_and_validate(field_value, true, @collection)
  end

  def new_field_for_column_spec(column_spec)
    column_spec[:validate_format_value_cached_field] ||= begin
      column_header = column_spec[:code]? column_spec[:code] : column_spec[:label]
      field = Field.new kind: column_spec[:kind].to_s, code: column_header, config: column_spec[:config]
      field.cache_for_read

      # We need the collection to validate site_fields
      field.collection = @collection

      field
    end
  end

  def error_description_for_type(field, column_spec, ex)
    if column_spec[:header].present?
      column_desc = "field '#{column_spec[:header]}' (#{(column_spec[:index] + 1).ordinalize} column)"
    else
      column_desc = "the #{(column_spec[:index] + 1).ordinalize} column"
    end
    "Some of the values in #{column_desc} #{field.error_description_for_invalid_values(ex)}."
  end

  def add_new_hierarchy_error(csv_column_number, hierarchy_errors)
    if hierarchy_errors.length >0 && hierarchy_errors[0][:new_hierarchy_columns].length >0
      hierarchy_errors[0][:new_hierarchy_columns] << csv_column_number
    else
      hierarchy_errors = [{:new_hierarchy_columns => [csv_column_number]}]
    end
    hierarchy_errors
  end
end