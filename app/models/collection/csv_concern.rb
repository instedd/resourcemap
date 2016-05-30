module Collection::CsvConcern
  extend ActiveSupport::Concern

  def csv_template
    CSV.generate do |csv|
      csv << csv_header
      csv << [1, "Site 1", 1.234, 5.678]
      csv << [2, "Site 2", 3.456, 4.567]
    end
  end

  def to_csv(elastic_search_csv_results, fields)
    CSV.generate do |csv|
      header = ['resmap-id', 'name', 'lat', 'long']
      fields.each do |field|
        field.csv_headers.each do |column_header|
          header << column_header
        end
      end
      header << 'last updated'
      csv << header

      elastic_search_csv_results.each do |result|
        source = result['_source']

        row = [source['id'], source['name'], source['location'].try(:[], 'lat'), source['location'].try(:[], 'lon')]
        fields.each do |field|
          source['properties'][field.code].each do |value|
            row << value
          end
        end
        row << Site.iso_string_to_rfc822(source['updated_at'])
        csv << row
      end
    end
  end

  def sample_csv(user = nil)
    fields = self.visible_fields_for(user, {snapshot_id: nil})

    CSV.generate do |csv|
      header = ['name', 'lat', 'long']
      writable_fields = writable_fields_for(user)
      writable_fields.each { |field| header << field.code }
      csv << header
      row = ['Paris', 48.86, 2.35]
      writable_fields.each do |field|
        row << Array(field.sample_value user).join(", ")
      end
      csv << row
    end
  end

  def decode_hierarchy_csv_file(file_path)
    begin
      csv = CSV.read(file_path)

      # Remove empty rows at the end
      while (last = csv.last) && last.all?(&:empty?)
        csv.pop
      end

      decode_hierarchy_csv(csv)
    rescue Exception => ex
      return [{error: ex.message}]
    end
  end

  def decode_hierarchy_csv(csv)

    # First read all items into a hash
    # And validate it's content
    items = validate_format(csv)

    # Build a dictionary of the items for quick access to the parents
    items_by_id = Hash[items.map { |order, item| [item[:id], item] }]

    # Add to parents
    items.each do |order, item|
      if item[:parent].present? && !item[:error].present?
        parent = items_by_id[item[:parent]]

        if parent
          parent[:sub] ||= []
          parent[:sub] << item
        end
      end
    end


    # Remove those that have parents, and at the same time delete their parent key
    items = items.reject do |order, item|
      if item[:parent] && !item[:error].present?
        item.delete :parent
        true
      else
        false
      end
    end

    items.values
  end

  def generate_error_description_list(hierarchy_csv)
    hierarchy_errors = []
    hierarchy_csv.each do |item|
      message = ""

      if item[:error]
        message << "Error: #{item[:error]}"
        message << " " + item[:error_description] if item[:error_description]
        message << " in line #{item[:order]}." if item[:order]
      end

      hierarchy_errors << message if !message.blank?
    end
    hierarchy_errors.join("<br/>").to_s
  end

  def validate_format(csv)
    i = 0
    items = {}

    # For validating the parents, make a set of all the IDs in the CSV
    all_ids = Set.new(csv.map { |csv_row| csv_row[0].strip })

    # Keep a set of the IDs already processed to check for duplicates
    seen_ids = Set.new

    csv.each do |row|
      item = {}
      if row[0] == 'ID'
        next
      else
        i = i+1
        item[:order] = i

        if !(row.length == 3 || row.length == 4)
          item[:error] = "Wrong format."
          item[:error_description] = "Invalid column number"
        else

          name = row[2].strip

          #Check unique id
          id = row[0].strip
          if seen_ids.include?(id)
            item[:error] = "Invalid id."
            item[:error_description] = "Hierarchy id should be unique"
            error = true
          end

          #Check parent id exists
          parent_id = row[1]
          if parent_id.present? && !all_ids.include?(parent_id.strip)
            item[:error] = "Invalid parent value."
            item[:error_description] = "ParentID should match one of the Hierarchy ids"
            error = true
          end

          if !error
            item[:id] = id
            item[:parent] = row[1].strip if row[1].present?
            item[:name] = name
            item[:type] = row[3].strip if row[3].present?
          end
        end

        seen_ids << id
        items[item[:order]] = item
      end
    end
    items
  end

  private

  def csv_header
    ["Site ID", "Name", "Lat", "Lng"]
  end
end
