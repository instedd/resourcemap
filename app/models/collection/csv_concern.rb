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
          row << Array(source['properties'][field.code]).join(", ")
        end
        row << Site.parse_date(source['updated_at']).rfc822
        csv << row
      end
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

    csv = CSV.new string_or_io, return_headers: false

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
          item[:error] = "wrong format"
          item[:error_description] = "invalid column number"
        else
          item[:id] = row[0].strip
          item[:parent] = row[1].strip if row[1].present?
          item[:name] = row[2].strip
        end

        items[item[:order]] = item
      end

    end

    # Add to parents
    items.each do |order, item|
      if item[:parent].present? && !item[:error].present?
        parent = items.first{|key, hash| hash[:id] == item[:parent]}[1]

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
