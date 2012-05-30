module Collection::CsvConcern
  extend ActiveSupport::Concern

  def csv_template
    CSV.generate do |csv|
      csv << csv_header
      csv << [1, "Site 1", 1.234, 5.678]
      csv << [2, "Site 2", 3.456, 4.567]
    end
  end

  def import_csv(user, string_or_io)
    Collection.transaction do
      csv = CSV.new string_or_io, return_headers: false

      new_sites = []
      csv.each do |row|
        next unless row[0].present? && row[0] != 'id'

        site = sites.new name: row[1].strip
        site.mute_activities = true
        site.lat = row[2].strip if row[2].present?
        site.lng = row[3].strip if row[3].present?
        new_sites << site
      end

      new_sites.each &:save!

      Activity.create! kind: 'collection_csv_imported', collection_id: id, user_id: user.id, 'data' => {'sites' => new_sites.length}
    end
  end

  def decode_hierarchy_csv(string_or_io)
    csv = CSV.new string_or_io, return_headers: false

    # First read all items into a hash
    items = {}
    csv.each do |row|
      next unless row.length == 3 && row[0].present? && row[0] != 'ID'
      item = {id: row[0].strip, name: row[2].strip}
      item[:parent] = row[1].strip if row[1].present?
      items[item[:id]] = item
    end

    # Add to parents
    items.each do |id, item|
      if item[:parent].present?
        parent = items[item[:parent]]
        if parent
          parent[:sub] ||= []
          parent[:sub] << item
        end
      end
    end

    # Remove those that have parents, and at the same time delete their parent key
    items = items.reject do |id, item|
      if item[:parent]
        item.delete :parent
        true
      else
        false
      end
    end

    items.values
  end

  private

  def csv_header
    ["Site ID", "Name", "Lat", "Lng"]
  end
end
