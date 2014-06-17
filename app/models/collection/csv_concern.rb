module Collection::CsvConcern
  extend ActiveSupport::Concern

  def csv_template
    CSV.generate do |csv|
      csv << csv_header
      csv << [1, "Site 1", 1.234, 5.678]
      csv << [2, "Site 2", 3.456, 4.567]
    end
  end

  def to_csv(elastic_search_api_results, user, snapshot_id = nil)
    fields = self.visible_fields_for(user, {snapshot_id: snapshot_id})

    CSV.generate do |csv|
      header = ['resmap-id', 'name', 'lat', 'long']
      fields.each { |field| header << field.code }
      header << 'last updated'
      csv << header

      elastic_search_api_results.each do |result|
        source = result['_source']

        row = [source['id'], source['name'], source['location'].try(:[], 'lat'), source['location'].try(:[], 'lon')]
        fields.each do |field|
          if field.kind == 'yes_no'
            row << (Field.yes?(source['properties'][field.code]) ? 'yes' : 'no')
          else
            row << Array(source['properties'][field.code]).join(", ")
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

  def import_csv(user, string_or_io)
    Collection.transaction do
      csv = CSV.new string_or_io, return_headers: false

      new_sites = []
      csv.each do |row|
        next unless row[0].present? && row[0] != 'resmap-id'

        site = sites.new name: row[1].strip, user: user
        site.mute_activities = true
        site.lat = row[2].strip if row[2].present?
        site.lng = row[3].strip if row[3].present?
        new_sites << site
      end

      new_sites.each &:save!

      Activity.create! item_type: 'collection', action: 'csv_imported', collection_id: id, user_id: user.id, 'data' => {'sites' => new_sites.length}
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
    # First read all items into an array
    # And validate it's content
    items = validate_format(csv)

    # Index items by id so we find them faster
    items_by_id = items.index_by { |item| item[:id] }

    # Add to parents
    items.each do |item|
      if item[:parent].present? && !item[:error].present?
        parent = items_by_id[item[:parent]]
        if parent
          parent[:sub] ||= []
          parent[:sub] << item
        end
      end
    end

    # Remove those that have parents, and at the same time delete their parent key
    items = items.reject do |item|
      if item[:parent] && !item[:error].present?
        item.delete :parent
        true
      else
        false
      end
    end

    items
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
    first = csv.first
    if first && first[0] == 'ID'
      csv = csv[1 .. -1]
    end

    # First map all rows to items
    items = csv.each_with_index.map do |row, index|
      order = index + 1

      unless row.length == 3 || row.length == 4
        item = {}
        item[:order] = order
        item[:error] = "Wrong format."
        item[:error_description] = "Invalid column number"
        next item
      end

      id, parent, name, type = row.map { |e| e && e.strip }

      item = {order: order, id: id, name: name}
      item[:parent] = parent if parent.present?
      item[:type] = type if type.present?
      item
    end

    # Get all ids so we can find parents quickly
    all_ids = items.map { |item| item[:id] }.to_set

    # These are the ids that we saw so far
    current_ids = Set.new

    # Now process errors
    items.select { |item| !item[:error] }.each do |item|
      id = item[:id]
      if current_ids.include? id
        item[:error] = "Invalid id."
        item[:error_description] = "Hierarchy id should be unique"
        next
      end
      current_ids.add id

      parent = item[:parent]
      if parent && !all_ids.include?(parent)
        item[:error] = "Invalid parent value."
        item[:error_description] = "ParentID should match one of the Hierarchy ids"
        next
      end
    end

    items
  end

  private

  def csv_header
    ["Site ID", "Name", "Lat", "Lng"]
  end
end
