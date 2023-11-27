class ImportWizard
  TmpDir = "#{Rails.root}/tmp/import_wizard"

  class << self
    def enqueue_job(user, collection, columns_spec)
      mark_job_as_pending user, collection

      # Enqueue job with user_id, collection_id, serialized column_spec
      Resque.enqueue ImportTask, user.id, collection.id, columns_spec
    end

    def cancel_pending_jobs(user, collection)
      mark_job_as_canceled_by_user(user, collection)
      delete_files(user, collection)
    end

    def import(user, collection, original_filename, contents)
      # Store representation of import job in database to enable status tracking later
      ImportJob.uploaded original_filename, user, collection

      FileUtils.mkdir_p TmpDir

      raise "Invalid file format. Only CSV files are allowed." unless File.extname(original_filename) == '.csv'

      begin
        File.open(csv_file_for(user, collection), "wb") { |file| file << contents }
        csv = read_csv_for(user, collection)
        raise CSV::MalformedCSVError, "all rows must have the same number of columns." unless csv.all?{|e| e.count == csv[0].count}

        # Create file that will contain data collected during validation in order to improve performance during the import execution
        File.open(aditional_data_file_for(user, collection), "wb") { |file| file << {} }

        csv
      rescue CSV::MalformedCSVError => ex
        raise "The file is not a valid CSV: #{ex.message}"
      end
    end

    def validate_sites_with_columns(user, collection, columns_spec)
      columns_spec.map!{|c| c.with_indifferent_access}
      csv = read_csv_for(user, collection)
      csv_columns = csv[1.. -1].transpose

      validated_data = {}
      validated_data[:sites] = get_sites(csv, user, collection, columns_spec, 1)
      validated_data[:sites_count] = csv.length - 1

      csv[0].map! { |r| r.strip if r }

      unless csv_columns.empty?
        validated_data[:errors] = calculate_errors(user, collection, columns_spec, csv_columns, csv[0])
      end

      # TODO: implement pagination
      validated_data
    end

    def calculate_errors(user, collection, columns_spec, csv_columns, header)
      #Add index to each column spec
      columns_spec.each_with_index do |column_spec, column_index|
        column_spec[:index] = column_index
      end

      sites_errors = {}

      # Columns validation
      proc_select_new_fields = Proc.new{columns_spec.select{|spec| spec[:use_as].to_s == 'new_field'}}
      sites_errors[:duplicated_code] = calculate_duplicated(proc_select_new_fields, 'code')
      sites_errors[:duplicated_label] = calculate_duplicated(proc_select_new_fields, 'label')
      sites_errors[:missing_label] = calculate_missing(proc_select_new_fields, 'label')
      sites_errors[:missing_code] = calculate_missing(proc_select_new_fields, 'code')

      sites_errors[:reserved_code] = calculate_reserved_code(proc_select_new_fields)

      collection_fields = collection.fields.includes(:layer)
      collection_fields.each(&:cache_for_read)

      sites_errors[:existing_code] = calculate_existing(columns_spec, collection_fields, 'code')
      sites_errors[:existing_label] = calculate_existing(columns_spec, collection_fields, 'label')

      # Calculate duplicated usage for default fields (lat, lng, id, name)
      proc_default_usages = Proc.new{columns_spec.reject{|spec| spec[:use_as].to_s == 'new_field' || spec[:use_as].to_s == 'existing_field' || spec[:use_as].to_s == 'ignore'}}
      sites_errors[:duplicated_usage] = calculate_duplicated(proc_default_usages, :use_as)
      # Add duplicated-usage-error for existing_fields
      proc_existing_fields = Proc.new{columns_spec.select{|spec| spec[:use_as].to_s == 'existing_field'}}
      sites_errors[:duplicated_usage].update(calculate_duplicated(proc_existing_fields, :field_id))

      # Name is mandatory
      sites_errors[:missing_name] = {:use_as => 'name'} if !(columns_spec.any?{|spec| spec[:use_as].to_s == 'name'})

      #### Choosing the pivot ####

      # Only one column will be marked to be used as id
      columns_used_as_id = columns_spec.select{|spec| spec[:use_as].to_s == 'id'}
      column_used_as_id = columns_used_as_id.first if columns_used_as_id.length > 0

      if column_used_as_id
        csv_column_used_as_id = csv_columns[column_used_as_id[:index]]

        if (!column_used_as_id[:id_matching_column] || column_used_as_id[:id_matching_column] == "resmap-id")
          sites_errors[:non_existent_site_id] = calculate_non_existent_site_id(collection.sites.map{|s| s.id.to_s}, csv_column_used_as_id, column_used_as_id[:index])
        else
          # Load the identifier field related to this column
          field_id = column_used_as_id[:id_matching_column]
          field = collection.identifier_fields.find field_id

          # This is not possible using UI
          raise "Invalid identifier field id #{field_id}" unless field

          sites_errors[:invalid_site_identifier] = calculate_invalid_identifier_id(csv_column_used_as_id, column_used_as_id[:index])
        end
      end

      sites_errors[:data_errors] = []
      sites_errors[:hierarchy_field_found] = []

      # Rows validation
      validator = ImportWizardRowValidator.new sites_errors,
                                                field,
                                                csv_columns,
                                                columns_spec,
                                                user,
                                                collection,
                                                collection_fields,
                                                csv_column_used_as_id,
                                                aditional_data_file_for(user, collection)
      validator.validate_row
    end

    def get_sites(csv, user, collection, columns_spec, page)
      csv_columns = csv[1 .. 10]
      processed_csv_columns = []
      csv_columns.each do |csv_column|
        processed_csv_columns << csv_column.map{|csv_field_value| {value: csv_field_value} }
      end
      processed_csv_columns
    end

    def guess_columns_spec(user, collection)
      rows = []
      CSV.foreach(csv_file_for user, collection) do |row|
        rows << row
      end
      ImportWizard::ImportSpecs.initial_guess rows, collection, user
    end

    def execute(user, collection, columns_spec)
      #Execute may be called with actual user and collection entities, or their ids.
      if !(user.is_a?(User) && collection.is_a?(Collection))
        #If the method's been called with ids instead of entities
        user = User.find(user)
        collection = Collection.find(collection)
      end

      import_job = ImportJob.last_for user, collection

      # Execution should continue only if the job is in status pending (user may canceled it)
      if import_job.status == 'pending'
        mark_job_as_in_progress(user, collection)

        Site::IndexUtils.bulk do
          Site::ActivityConcern.bulk do
            HistoryConcern.bulk do
              execute_with_entities(user, collection, columns_spec)
            end
          end
        end
      end
    end

    def execute_with_entities(user, collection, columns_spec)
      spec_object = ImportWizard::ImportSpecs.new columns_spec, collection

      # Validate new fields
      spec_object.validate_new_columns_do_not_exist_in_collection

      # Read all the CSV to memory
      rows = read_csv_for(user, collection)

      # Put the index of the row in the columns spec
      rows[0].each_with_index do |header, i|
        next if header.blank?
        header = header.strip
        spec_object.annotate_index header, i
      end

      # Get the id spec

      id_column = spec_object.create_id_column collection

      # Also get the name spec, as the name is mandatory
      name_spec = spec_object.name_column

      new_layer = spec_object.create_import_wizard_layer user

      begin
        sites = []

        # Now process all rows
        rows[1 .. -1].each do |row|

          # Check that the name is present
          next unless row[name_spec[:index]].present?

          # Load or create site from the ID column spec if it exists (according to the row value)
          # If there is not an id_column, create a new site
          site = if id_column
            id_column.find_or_create_site(collection, row[id_column.column_spec_index])
          else
            collection.sites.new properties: {}, from_import_wizard: true
          end

          site.user = user
          sites << site

          # Optimization
          site.collection = collection

          # According to the spec
          spec_object.each_column do |column_spec|
            value = row[column_spec.index].try(:strip) || ""
            column_spec.process row, site, value
          end
        end

        Collection.transaction do

          spec_object.new_fields.each_value do |field|
            field.save!
          end

          # Force computing bounds and such in memory, so a thousand callbacks are not called
          collection.compute_geometry_in_memory

          # Reload collection in order to invalidate cached collection.fields copy and to load the new ones
          collection.fields.reload

          # Generate default values for luhn fields
          luhn_fields = collection.identifier_fields.select(&:has_luhn_format?)

          luhn_fields.each  do |luhn_field|

            # The next luhn value will be the max between the higher number in the CSV and the higher number in the collection
            next_luhn_value_collection = luhn_field.default_value_for_create(collection)
            last_luhn_value_csv = JSON.load(File.read(aditional_data_file_for(user, collection)))[luhn_field.es_code]
            next_luhn_value_csv = luhn_field.format_implementation.next_luhn(last_luhn_value_csv) if last_luhn_value_csv
            next_luhn_value = if (next_luhn_value_csv && (next_luhn_value_csv > next_luhn_value_collection)) then next_luhn_value_csv else next_luhn_value_collection end

            sites.each do |site|
              # If the site already has a value for the luhn field we don't want to generate a new one
              if site.properties_was && site.properties_was[luhn_field.es_code].present?
                site.properties[luhn_field.es_code] = site.properties_was[luhn_field.es_code]
              elsif site.properties[luhn_field.es_code].blank?
                site.properties[luhn_field.es_code] = next_luhn_value
                next_luhn_value = luhn_field.format_implementation.next_luhn(next_luhn_value)
              end
            end
          end

          sites.each { |site| site.assign_default_values_for_update }

          # This will update the existing sites
          sites.each { |site| site.save! unless site.new_record? }

          # And this will create the new ones
          collection.save!

          mark_job_as_finished(user, collection)
        end

      rescue Exception => ex
        # Delete layer created by this import process if something unexpectedly fails
        new_layer.destroy if new_layer
        raise ex
      end

      delete_files(user, collection)
    end

    def delete_files(user, collection)
      File.delete(csv_file_for(user, collection))
      File.delete(aditional_data_file_for(user, collection))
    end

    def mark_job_as_pending(user, collection)
      # Move the corresponding ImportJob to status pending, since it'll be enqueued
      (ImportJob.last_for user, collection).pending
    end

    def mark_job_as_canceled_by_user(user, collection)
      (ImportJob.last_for user, collection).canceled_by_user
    end

    def mark_job_as_in_progress(user, collection)
      (ImportJob.last_for user, collection).in_progress
    end

    def mark_job_as_finished(user, collection)
      (ImportJob.last_for user, collection).finish
    end

    private

    def calculate_non_existent_site_id(valid_site_ids, csv_column, resmap_id_column_index)
      invalid_ids = []
      csv_column.each_with_index do |csv_field_value, field_number|
        invalid_ids << field_number unless (csv_field_value.blank? || valid_site_ids.include?(csv_field_value.to_s))
      end
      [{rows: invalid_ids, column: resmap_id_column_index}] if invalid_ids.length >0
    end

    def calculate_invalid_identifier_id(csv_column, identifier_column_index)
      invalid_ids = []
      csv_column.each_with_index do |csv_field_value, field_number|
        invalid_ids << field_number if csv_field_value.blank?
      end
      [{rows: invalid_ids, column: identifier_column_index}] if invalid_ids.length >0
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

    def calculate_reserved_code(selection_block)
      spec_to_validate = selection_block.call()
      invalid_columns = {}
      spec_to_validate.each do |column_spec|
        if Field.reserved_codes().include?(column_spec[:code])
          if invalid_columns[column_spec[:code]]
            invalid_columns[column_spec[:code]] << column_spec[:index]
          else
            invalid_columns[column_spec[:code]] = [column_spec[:index]]
          end
        end
      end
      invalid_columns
    end

    def calculate_missing(selection_block, missing_value)
      spec_to_validate = selection_block.call()
      missing_value_columns = []
      spec_to_validate.each do |column_spec|
        if column_spec[missing_value].blank?
          if missing_value_columns.length >0
            missing_value_columns << column_spec[:index]
          else
            missing_value_columns = [column_spec[:index]]
          end
        end
      end
      {:columns => missing_value_columns} if missing_value_columns.length >0
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

    def read_csv_for(user, collection)
      csv = CSV.read(csv_file_for(user, collection))

      # Remove empty rows at the end
      while (last = csv.last) && last.empty?
        csv.pop
      end

      csv
    end

    def aditional_data_file_for(user, collection)
      "#{TmpDir}/#{user.id}_#{collection.id}_aditional_data.json"
    end

    def csv_file_for(user, collection)
      "#{TmpDir}/#{user.id}_#{collection.id}.csv"
    end
  end
end
