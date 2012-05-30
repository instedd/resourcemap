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

    def sample(user, collection)
      rows = []
      i = 0
      CSV.foreach(file_for user, collection) do |row|
        rows << row
        i += 1
        break if i == 26
      end
      to_columns rows
    end

    def execute(user, collection, columns_spec)
      # Easier manipulation
      columns_spec.map! &:with_indifferent_access

      # Read all the CSV to memory
      rows = CSV.read file_for(user, collection)

      # Put the index of the row in the columns spec
      rows[0].each_with_index do |row, i|
        next if row.blank?

        row = row.strip
        spec = columns_spec.find{|x| x[:name].strip == row}
        spec[:index] = i if spec
      end

      # Also get the name spec, as the name is mandatory
      name_spec = columns_spec.find{|x| x[:kind] == 'name'}

      # Relate code and label select kinds for 'select one' and 'select many'
      columns_spec.each do |spec|
        if spec[:kind] == 'select_one' || spec[:kind] == 'select_many'
          if spec[:selectKind] == 'code'
            spec[:related] = columns_spec.find{|x| x[:code] == spec[:code] && x[:selectKind] == 'label'}
          end
        end
      end

      # Prepare the new layer
      layer = collection.layers.new name: collection.name, ord: collection.next_layer_ord
      layer.collection = collection
      layer.mute_activities = true

      # Prepare the fields: we index by code, so later we can reference them faster
      fields = {}

      # Fill the fields with the column specs.
      # We completely ignore the ones with selectKind equal to 'label', as processing those with
      # 'code' and 'both' is enough
      spec_i = 1
      columns_spec.each do |spec|
        if (spec[:kind] == 'text' || spec[:kind] == 'numeric' || spec[:kind] == 'select_one' || spec[:kind] == 'select_many') && spec[:selectKind] != 'label'
          fields[spec[:code]] = layer.fields.new code: spec[:code], name: spec[:label], kind: spec[:kind], ord: spec_i
          fields[spec[:code]].layer = layer
          spec_i += 1
        end
        if spec[:selectKind] == 'code'
          spec[:related] = columns_spec.find{|x| x[:code] == spec[:code] && x[:selectKind] == 'label'}
        end
      end

      sites = []

      # Now process all rows
      rows[1 .. -1].each do |row|
        # Check that the name is present
        next unless row[name_spec[:index]].present?

        site = collection.sites.new properties: {}, collection_id: collection.id
        site.mute_activities = true
        sites << site

        # Optimization
        site.collection = collection

        # According to the spec
        columns_spec.each do |spec|
          next unless spec[:index]

          value = row[spec[:index]].try(:strip)

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

          # Assign the site value
          case spec[:kind]
          when 'name'
            site.name = value
          when 'lat'
            site.lat = value
          when 'lng'
            site.lng = value
          when 'text', 'select_one', 'select_many'
            site.properties[spec[:code]] = value
          when 'numeric'
            site.properties[spec[:code]] = value.to_i_or_f
          end

        end
      end

      Collection.transaction do
        layer.save!

        # Force computing bounds and such in memory, so a thousand callbacks are not called
        collection.compute_geometry_in_memory

        # Need to change site properties from code to field.es_code
        sites.each { |site| site.properties = Hash[site.properties.map { |k, v| [fields[k].es_code, v] }] }

        collection.save!

        Activity.create! kind: 'collection_imported', collection_id: collection.id, layer_id: layer.id, user_id: user.id, 'data' => {'sites' => sites.length}
      end
    end

    private

    def to_columns(rows)
      columns = rows[0].select(&:present?).map{|x| {:name => x, :sample => "", :kind => :text, :code => x.downcase.gsub(/\s+/, ''), :label => x.titleize}}
      columns.each_with_index do |column, i|
        rows[1 .. 4].each do |row|
          if row[i]
            column[:value] = row[i].to_s unless column[:value]
            column[:sample] << ", " if column[:sample].present?
            column[:sample] << row[i].to_s
          end
        end
        column[:kind] = guess_column_kind(column, rows, i)
      end
    end

    def guess_column_kind(column, rows, i)
      return :lat if column[:name] =~ /^\s*lat/i
      return :lng if column[:name] =~ /^\s*(lon|lng)/i

      found = false

      rows[1 .. -1].each do |row|
        next if row[i].blank?

        found = true

        return :text if row[i].start_with?('0')
        Float(row[i]) rescue return :text
      end

      found ? :numeric : :ignore
    end

    def file_for(user, collection)
      "#{TmpDir}/#{user.id}_#{collection.id}.csv"
    end
  end
end
