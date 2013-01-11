class ImportWizard
  TmpDir = "#{Rails.root}/tmp/import_wizard"

  class << self
    def import(user, collection, contents)
      FileUtils.mkdir_p TmpDir
      File.open(file_for(user, collection), "wb") { |file| file << contents }

      # Just to validate its contents
      csv = CSV.new contents
      csv.each { |row| }
    end

    def validate_sites_with_columns(user, collection, columns_spec)
      columns_spec.map!{|c| c.with_indifferent_access}
      validated_data = {}
      csv = CSV.read file_for(user, collection)
      csv_columns = csv[1.. -1].transpose
      csv[0].map!{|r| r.strip}

      validated_data[:errors] = calculate_errors(user, collection, columns_spec, csv_columns, csv[0])
      # TODO: implement pagination
      validated_data[:sites] = get_sites(user, collection, columns_spec, 1)
      validated_data
    end

    def validate_sites_with_column(user, collection, column_spec)
      column_spec = column_spec.with_indifferent_access
      csv = CSV.read file_for(user, collection)
      csv[0].map!{|r| r.strip}
      column_index = csv[0].index(column_spec[:header])
      csv_column = csv[1 .. -1].transpose[column_index]

      sites = csv_column.map{|csv_field_value| {value: csv_field_value}}

      #TODO: Refactor this duplicated code
      sites_errors = {}
      sites_errors[:hierarchy_field_found] = []
      sites_errors[:usage_missing] = []
      sites_errors[:data_errors] = []

      #At this point we asume that no columns with duplicated usage or columns with duplicated/existing code or label are found in column_specs.
      #This validations are performed client side

      sites_errors[:hierarchy_field_found] << column_index if column_spec[:use_as] == 'new_field' && column_spec[:kind] == 'hierarchy'
      errors_for_column = validate_column(user, collection, column_spec, collection.fields, csv_column, column_index)
      sites_errors[:data_errors] << errors_for_column unless errors_for_column.nil?

      { sites: sites, errors: sites_errors}
    end

    def calculate_errors(user, collection, columns_spec, csv_columns, header)
      #This is the new error model
      #Add index to each column spec
      columns_spec.each_with_index do |column_spec, column_index|
        column_spec[:index] = column_index
      end

      sites_errors = {}

      proc_select_new_fields = Proc.new{columns_spec.select{|spec| spec[:use_as] == 'new_field'}}
      sites_errors[:duplicated_code] = calculate_duplicated(proc_select_new_fields, 'code')
      sites_errors[:duplicated_label] = calculate_duplicated(proc_select_new_fields, 'label')

      collection_fields = collection.fields.all(:include => :layer)
      sites_errors[:existing_code] = calculate_existing(columns_spec, collection_fields, 'code')
      sites_errors[:existing_label] = calculate_existing(columns_spec, collection_fields, 'label')

      sites_errors[:usage_missing] = []

      # Calculate duplicated usage for default fields (lat, lng, id, name)
      proc_default_usages = Proc.new{columns_spec.reject{|spec| spec[:use_as] == 'new_field' || spec[:use_as] == 'existing_field' || spec[:use_as] == 'ignore'}}
      sites_errors[:duplicated_usage] = calculate_duplicated(proc_default_usages, :use_as)
      # Add duplicated-usage-error for existing_fields
      proc_existing_fields = Proc.new{columns_spec.select{|spec| spec[:use_as] == 'existing_field'}}
      sites_errors[:duplicated_usage].update(calculate_duplicated(proc_existing_fields, :field_id))

      sites_errors[:data_errors] = []
      sites_errors[:hierarchy_field_found] = []

      csv_columns.each_with_index do |csv_column, csv_column_number|
        column_spec = columns_spec[csv_column_number]
        sites_errors[:hierarchy_field_found] = add_new_hierarchy_error(csv_column_number, sites_errors[:hierarchy_field_found]) if column_spec[:use_as] == 'new_field' && column_spec[:kind] == 'hierarchy'
        errors_for_column = validate_column(user, collection, column_spec, collection_fields, csv_column, csv_column_number)
        sites_errors[:data_errors] << errors_for_column unless errors_for_column.nil?
      end

      sites_errors
    end

    def add_new_hierarchy_error(csv_column_number, hierarchy_errors)
      if hierarchy_errors.length >0 && hierarchy_errors[0][:new_hierarchy_columns].length >0
        hierarchy_errors[0][:new_hierarchy_columns] << csv_column_number
      else
        hierarchy_errors = [{:new_hierarchy_columns => [csv_column_number]}]
      end
      hierarchy_errors
    end

    def get_sites(user, collection, columns_spec, page)
      csv = CSV.read file_for(user, collection)
      csv_columns = csv[1 .. 11]
      processed_csv_columns = []
      csv_columns.each do |csv_column|
        processed_csv_columns << csv_column.map{|csv_field_value| {value: csv_field_value} }
      end
      processed_csv_columns
    end

    def guess_columns_spec(user, collection)
      rows = []
      CSV.foreach(file_for user, collection) do |row|
        rows << row
      end
      to_columns collection, rows, user.admins?(collection)
    end

    def execute(user, collection, columns_spec)
      # Easier manipulation
      columns_spec.map! &:with_indifferent_access

      existing_fields = collection.fields.index_by &:id

      # Validate new fields
      validate_columns(collection, columns_spec)

      # Read all the CSV to memory
      rows = CSV.read file_for(user, collection)

      # Put the index of the row in the columns spec
      rows[0].each_with_index do |row, i|
        next if row.blank?

        row = row.strip
        spec = columns_spec.find{|x| x[:header].strip == row}
        spec[:index] = i if spec

      end

      # Get the id spec
      id_spec = columns_spec.find{|x| x[:use_as] == 'id'}

      # Also get the name spec, as the name is mandatory
      name_spec = columns_spec.find{|x| x[:use_as] == 'name'}

      # Relate code and label select kinds for 'select one' and 'select many'
      columns_spec.each do |spec|
        if spec[:use_as] == 'new_field'
          if spec[:kind] == 'select_one' || spec[:kind] == 'select_many'
            if spec[:selectKind] == 'code'
              spec[:related] = columns_spec.find{|x| x[:code] == spec[:code] && x[:selectKind] == 'label'}
            end
          end
        end
      end

      # Prepare the new layer
      layer = Layer.new name: 'Import wizard', ord: collection.next_layer_ord
      layer.user = user
      layer.collection = collection

      # Prepare the fields: we index by code, so later we can reference them faster
      fields = {}

      # Fill the fields with the column specs.
      # We completely ignore the ones with selectKind equal to 'label', as processing those with
      # 'code' and 'both' is enough
      spec_i = 1
      columns_spec.each do |spec|
        if spec[:use_as] == 'new_field'
          if spec[:selectKind] != 'label'
            fields[spec[:code]] = layer.fields.new code: spec[:code], name: spec[:label], kind: spec[:kind], ord: spec_i
            fields[spec[:code]].layer = layer
            spec_i += 1
          end
          if spec[:selectKind] == 'code'
            spec[:related] = columns_spec.find{|x| x[:code] == spec[:code] && x[:selectKind] == 'label'}
          end
        end
      end

      sites = []

      # Now process all rows
      rows[1 .. -1].each do |row|

        # Check that the name is present
        next unless row[name_spec[:index]].present?

        site = nil
        site = collection.sites.find_by_id row[id_spec[:index]] if id_spec && row[id_spec[:index]].present?
        site ||= collection.sites.new properties: {}, collection_id: collection.id

        site.user = user
        sites << site

        # Optimization
        site.collection = collection

        # According to the spec
        columns_spec.each do |spec|
          next unless spec[:index]

          value = row[spec[:index]].try(:strip)

          case spec[:use_as]
          when 'new_field'
            value = validate_format_value(spec, value, collection)

            # For select one and many we need to collect the fields options
            if spec[:kind] == 'select_one' || spec[:kind] == 'select_many'
              field = fields[spec[:code]]
              field.config ||= {'options' => [], 'next_id' => 1}

              code = nil
              label = nil

              # Compute code and label based on the selectKind
              case spec[:selectKind]
              when 'code'
                next unless spec[:related]

                code = value
                label = row[spec[:related][:index]]
              when 'label'
                # Processing just the code is enough
                next
              when 'both'
                code = value
                label = value
              end

              # Add to options, if not already present
              if code.present? && label.present?
                existing = field.config['options'].find{|x| x['code'] == code}
                if existing
                  value = existing['id']
                else
                  value = field.config['next_id']
                  field.config['options'] << {'id' => field.config['next_id'], 'code' => code, 'label' => label}
                  field.config['next_id'] += 1
                end
              end
            end

            field = fields[spec[:code]]
            site.properties[field] = field.strongly_type value

          when 'existing_field'
            existing_field = existing_fields[spec[:field_id].to_i]
            if existing_field
              if value.blank?
                site.properties[existing_field] = nil
              else
                case existing_field.kind
                  when 'numeric', 'text', 'site', 'user'
                    site.properties[existing_field] = existing_field.apply_format_update_validation(value, true, collection)
                  when 'select_one'
                    existing_option = existing_field.config['options'].find { |x| x['code'] == value }
                    if existing_option
                      site.properties[existing_field] = existing_option['id']
                    else
                      site.properties[existing_field] = existing_field.config['next_id']
                      existing_field.config['options'] << {'id' => existing_field.config['next_id'], 'code' => value, 'label' => value}
                      existing_field.config['next_id'] += 1
                    end
                  when 'select_many'
                    site.properties[existing_field] = []
                    value.split(',').each do |v|
                      v = v.strip
                      existing_option = existing_field.config['options'].find { |x| x['code'] == v }
                      if existing_option
                        site.properties[existing_field] << existing_option['id']
                      else
                        site.properties[existing_field] << existing_field.config['next_id']
                        existing_field.config['options'] << {'id' => existing_field.config['next_id'], 'code' => v, 'label' => v}
                        existing_field.config['next_id'] += 1
                      end
                    end
                  when 'hierarchy'
                    site.properties[existing_field] = existing_field.apply_format_update_validation(value, true, collection)
                  when 'date'
                    site.properties[existing_field] = existing_field.apply_format_update_validation(value, true, collection)
                end
                if Field::PluginKinds.has_key? existing_field.kind
                  site.properties[existing_field] = existing_field.apply_format_update_validation(value, true, collection)
                end
              end
              fields[existing_field.code] = existing_field
            end

          when 'name'
            site.name = value
          when 'lat'
            site.lat = value
          when 'lng'
            site.lng = value
          end
        end
      end

      Collection.transaction do
        new_fields = layer.fields.select(&:new_record?)

        # Update existing fields
        fields.each_value do |field|
          field.save! unless field.new_record?
        end

        # Create layer and new fields
        layer.save! if new_fields.length > 0

        # Force computing bounds and such in memory, so a thousand callbacks are not called
        collection.compute_geometry_in_memory

        # Need to change site properties from code to field.es_code
        sites.each { |site| site.properties = Hash[site.properties.map { |k, v| [k.is_a?(Field) ? k.es_code : k, v] }] }

        # This will update the existing sites
        sites.each { |site| site.save! unless site.new_record? }

        # And this will create the new ones
        collection.save!
      end

      delete_file(user, collection)

    end

    def delete_file(user, collection)
      File.delete(file_for(user, collection))
    end

    def validate_columns(collection, columns_spec)
      collection_fields = collection.fields.all(:include => :layer)
      columns_spec.each do |col_spec|
        if col_spec[:use_as] == 'new_field'
          # Validate code
          found = collection_fields.detect{|f| f.code == col_spec[:code]}
          if found
            raise "Can't save field from column #{col_spec[:header]}: A field with code '#{col_spec[:code]}' already exists in the layer named #{found.layer.name}"
          end
          # Validate name
          found = collection_fields.detect{|f| f.name == col_spec[:label]}
          if found
            raise "Can't save field from column #{col_spec[:header]}: A field with label '#{col_spec[:label]}' already exists in the layer named #{found.layer.name}"
          end
        end
      end
    end

    private

    def validate_column(user, collection, column_spec, fields, csv_column, column_number)
      if column_spec[:use_as].to_sym == :existing_field
        field = fields.detect{|e| e.id.to_s == column_spec[:field_id].to_s}
      end
      validated_csv_column = []
      csv_column.each_with_index do |csv_field_value, field_number|
        begin
          validate_column_value(column_spec, csv_field_value, field, collection)
        rescue => ex
          validated_csv_column << {description: ex.message, row: field_number}
        end
      end

      grouped_errors = nil
      validated_columns_grouped = validated_csv_column.group_by{|e| e[:description]}
      validated_columns_grouped.each do |error_type|
        if error_type[0]
          # For the moment we only have one kind of error for each column.
          grouped_errors = {description: error_type[0], column: column_number, rows:error_type[1].map{|e| e[:row]}}
        end
      end
      grouped_errors
    end

    def calculate_duplicated(selection_block, groping_field)
      spec_to_validate = selection_block.call()
      spec_by_field = spec_to_validate.group_by{ |s| s[groping_field]}
      duplicated_columns = {}
      spec_by_field.each do |column_spec|
        if column_spec[1].length > 1
          duplicated_columns[column_spec[0]] = column_spec[1].map{|spec| spec[:index] }
        end
      end
      duplicated_columns
    end

    def calculate_existing(columns_spec, collection_fields, grouping_field)
      spec_to_validate = columns_spec.select {|spec| spec[:use_as] == 'new_field'}
      existing_columns = {}
      spec_to_validate.each do |column_spec|
        #Refactor this
        if grouping_field == 'code'
          found = collection_fields.detect{|f| f.code == column_spec[grouping_field]}
        elsif grouping_field == 'label'
          found = collection_fields.detect{|f| f.name == column_spec[grouping_field]}
        end
        if found
          if existing_columns[column_spec[grouping_field]]
            existing_columns[column_spec[grouping_field]] << column_spec[:index]
          else
            existing_columns[column_spec[grouping_field]] = [column_spec[:index]]
          end
        end
      end
      existing_columns
    end

    def validate_column_value(column_spec, field_value, field, collection)
      if field
        field.apply_format_update_validation(field_value, true, collection)
      else
        validate_format_value(column_spec, field_value, collection)
      end
    end

    def validate_format_value(column_spec, field_value, collection)
      # Bypass some field validations
      if column_spec[:kind] == 'hierarchy'
        raise "Hierarchy fields can only be created via web in the Layers page"
      elsif column_spec[:kind] == 'select_one' || column_spec[:kind] == 'select_many'
        # options will be created
        return field_value
      end

      column_header = column_spec[:code]? column_spec[:code] : column_spec[:label]

      sample_field = Field.new kind: column_spec[:kind], code: column_header
      sample_field.apply_format_update_validation(field_value, true, collection)
    end

    def to_columns(collection, rows, admin)
      fields = collection.fields.index_by &:code

      columns = rows[0].select(&:present?).map{|x| {:header => x.strip, :kind => :text, :code => x.downcase.gsub(/\s+/, ''), :label => x.titleize}}
      columns.each_with_index do |column, i|
        guess_column_usage(column, fields, rows, i, admin)
      end
    end

    def guess_column_usage(column, fields, rows, i, admin)
      if (field = fields[column[:header]])
        column[:use_as] = :existing_field
        column[:layer_id] = field.layer_id
        column[:field_id] = field.id
        column[:kind] = field.kind.to_sym
        return
      end

      if column[:header] =~ /^resmap-id$/i
        column[:use_as] = :id
        column[:kind] = :id
        return
      end

      if column[:header] =~ /^name$/i
        column[:use_as] = :name
        column[:kind] = :name
        return
      end

      if column[:header] =~ /^\s*lat/i
        column[:use_as] = :lat
        column[:kind] = :location
        return
      end

      if column[:header] =~ /^\s*(lon|lng)/i
        column[:use_as] = :lng
        column[:kind] = :location
        return
      end

      if column[:header] =~ /last updated/i
        column[:use_as] = :ignore
        column[:kind] = :ignore
        return
      end

      if not admin
        column[:use_as] = :ignore
        return
      end

      found = false

      rows[1 .. -1].each do |row|
        next if row[i].blank?

        found = true

        if row[i].start_with?('0')
          column[:use_as] = :new_field
          column[:kind] = :text
          return
        end

        begin
          Float(row[i])
        rescue
          column[:use_as] = :new_field
          column[:kind] = :text
          return
        end
      end

      if found
        column[:use_as] = :new_field
        column[:kind] = :numeric
      else
        column[:use_as] = :ignore
      end
    end

    def file_for(user, collection)
      "#{TmpDir}/#{user.id}_#{collection.id}.csv"
    end
  end
end
