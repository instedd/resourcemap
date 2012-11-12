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
      csv = CSV.read file_for(user, collection)
      validated_csv_columns = []
      csv_columns = csv[1 .. -1].transpose
      csv_columns.each_with_index do |csv_column, csv_column_number|

        column_spec = columns_spec[csv_column_number]
        if column_spec[:usage].to_sym == :existing_field
          field = Field.find column_spec[:field_id]
        end
        validated_csv_column = []
        csv_column.each do |csv_field_value|
          begin
            validate_column_value(column_spec, csv_field_value, field, collection)
          rescue => ex
            error = ex.message
          end
          validated_csv_column << {value: csv_field_value, error: error}
        end
        validated_csv_columns << validated_csv_column
      end
      validated_csv_columns.transpose
    end

    def guess_columns_spec(user, collection)
      rows = []
      i = 0

      CSV.foreach(file_for user, collection) do |row|
        rows << row
      end
      to_columns collection, rows, user.admins?(collection)
    end

    def execute(user, collection, columns_spec)
      # Easier manipulation
      columns_spec.map! &:with_indifferent_access

      existing_fields = collection.fields.index_by &:id

      # Read all the CSV to memory
      rows = CSV.read file_for(user, collection)

      # Put the index of the row in the columns spec
      rows[0].each_with_index do |row, i|
        next if row.blank?

        row = row.strip
        spec = columns_spec.find{|x| x[:name].strip == row}
        spec[:index] = i if spec

      end

      # Get the id spec
      id_spec = columns_spec.find{|x| x[:usage] == 'id'}

      # Also get the name spec, as the name is mandatory
      name_spec = columns_spec.find{|x| x[:usage] == 'name'}

      # Relate code and label select kinds for 'select one' and 'select many'
      columns_spec.each do |spec|
        if spec[:usage] == 'new_field'
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
        if spec[:usage] == 'new_field'
          if (spec[:kind] == 'text' || spec[:kind] == 'numeric' || spec[:kind] == 'select_one' || spec[:kind] == 'select_many') && spec[:selectKind] != 'label'
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

          case spec[:usage]
          when 'new_field'
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


    private

    def validate_column_value(column_spec, field_value, field, collection)
      if field
        field.apply_format_update_validation(field_value, true, collection)
      else
        validate_format(column_spec, field_value, collection)
      end
    end

    def validate_format(column_spec, field_value, collection)
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

      columns = rows[0].select(&:present?).map{|x| {:name => x.strip, :kind => :text, :code => x.downcase.gsub(/\s+/, ''), :label => x.titleize}}
      columns.each_with_index do |column, i|
        rows[1 .. 4].each do |row|
          if row[i]
            column[:value] = row[i].to_s unless column[:value].present?
          end
        end
        guess_column_usage(column, fields, rows, i, admin)
      end
    end

    def guess_column_usage(column, fields, rows, i, admin)
      if (field = fields[column[:name]])
        column[:usage] = :existing_field
        column[:layer_id] = field.layer_id
        column[:field_id] = field.id
        column[:kind] = field.kind.to_sym
        return
      end

      if column[:name] =~ /^resmap-id$/i
        column[:usage] = :id
        column[:kind] = :id
        return
      end

      if column[:name] =~ /^name$/i
        column[:usage] = :name
        column[:kind] = :name
        return
      end

      if column[:name] =~ /^\s*lat/i
        column[:usage] = :lat
        column[:kind] = :location
        return
      end

      if column[:name] =~ /^\s*(lon|lng)/i
        column[:usage] = :lng
        column[:kind] = :location
        return
      end

      if column[:name] =~ /last updated/i
        column[:usage] = :ignore
        column[:kind] = :ignore
        return
      end

      if not admin
        column[:usage] = :ignore
        return
      end

      found = false

      rows[1 .. -1].each do |row|
        next if row[i].blank?

        found = true

        if row[i].start_with?('0')
          column[:usage] = :new_field
          column[:kind] = :text
          return
        end

        begin
          Float(row[i])
        rescue
          column[:usage] = :new_field
          column[:kind] = :text
          return
        end
      end

      if found
        column[:usage] = :new_field
        column[:kind] = :numeric
      else
        column[:usage] = :ignore
      end
    end

    def file_for(user, collection)
      "#{TmpDir}/#{user.id}_#{collection.id}.csv"
    end
  end
end
