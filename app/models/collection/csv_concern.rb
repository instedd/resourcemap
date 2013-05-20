module Collection::CsvConcern
  extend ActiveSupport::Concern

  def csv_template
    CSV.generate do |csv|
      csv << csv_header
      csv << [1, "Site 1", 1.234, 5.678]
      csv << [2, "Site 2", 3.456, 4.567]
    end
  end

  def to_csv(elastic_search_api_results = new_search.unlimited.api_results)
    fields = self.fields.all

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
    fields = self.fields.all

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

        site = sites.new name: row[1].strip
        site.mute_activities = true
        site.lat = row[2].strip if row[2].present?
        site.lng = row[3].strip if row[3].present?
        new_sites << site
      end

      new_sites.each &:save!

      Activity.create! item_type: 'collection', action: 'csv_imported', collection_id: id, user_id: user.id, 'data' => {'sites' => new_sites.length}
    end
  end

  def decode_hierarchy_csv(string_or_io)

    csv = CSV.read(string_or_io, :encoding => 'utf-8')

    # First read all items into a hash
    items = {}
    i = 0

    csv.each do |row|
      item = {}
      if row[0] == 'ID'
        next
      else
        i = i+1
        item[:order] = i

        if row.length != 3
          item[:error] = "Wrong format."
          item[:error_description] = "Invalid column number"
        else

          #Check unique name
          name = row[2].strip
          if items.any?{|item| item.second[:name] == name}
            item[:error] = "Invalid name."
            item[:error_description] = "Hierarchy name should be unique"
          else
            #Check unique id
            id = row[0].strip
            if items.any?{|item| item.second[:id] == id}
              item[:error] = "Invalid id."
              item[:error_description] = "Hierarchy id should be unique"
            else
              item[:id] = id
              item[:parent] = row[1].strip if row[1].present?
              item[:name] = name
            end
          end
        end

        items[item[:order]] = item
      end

    end

    # Add to parents
    items.each do |order, item|
      if item[:parent].present? && !item[:error].present?
        parent_candidates = items.select{|key, hash| hash[:id] == item[:parent]}

        if parent_candidates
          parent = parent_candidates.first[1]
        end

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

    rescue Exception => ex
      return [{error: ex.message}]

  end

  private

  def csv_header
    ["Site ID", "Name", "Lat", "Lng"]
  end
end
