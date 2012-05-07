require 'csv'

module Collection::CsvConcern
  extend ActiveSupport::Concern

  def csv_template
    CSV.generate do |csv|
      csv << csv_header
      csv << [1, "Group", "Group A", 1.234, 5.678, nil, "none/manual/automatic"]
      csv << [2, "Site", "Site A.1", 2.345, 6.789, 1, nil]
      csv << [3, "Group", "Group B", 3.456, 4.567, nil, "none/manual/automatic"]
      csv << [4, "Site", "Site B.1", 4.567, 5.678, 2, nil]
    end
  end

  def export_csv
    CSV.generate do |csv|
      csv << csv_header
      sites.each do |site|
        csv << [site.id, site.group ? "Group" : "Site", site.name, site.lat, site.lng, site.parent_id, site.group ? site.location_mode : nil]
      end
    end
  end

  def import_csv(user, string_or_io)
    Collection.transaction do
      csv = CSV.new string_or_io, return_headers: false

      sites_count = 0
      groups_count = 0

      # Create a hash of id => [site, parent]
      hash = Hash.new
      csv.each do |row|
        next unless row[0].present? && row[0] != 'id'

        site = sites.new name: row[2].strip
        site.mute_activities = true
        if row[1].try(:strip).try(:downcase) == 'group'
          site.group = true
          groups_count += 1
        else
          sites_count += 1
        end
        site.lat = row[3].strip if row[3].present?
        site.lng = row[4].strip if row[4].present?
        site.location_mode = row[6].strip if row[6].present?
        hash[row[0].strip] = [site, row[5]]
      end

      # Assign parents
      hash.each_value do |site, parent_id|
        next unless parent_id.present?

        parent = hash[parent_id.strip] or next
        parent = parent[0]
        parent.sites.push site
        parent.group = true
      end

      # Save all sites that are roots (don't have a parent)
      hash.each_value do |site, parent_id|
        site.save! if parent_id.blank?
      end

      Activity.create! kind: 'collection_csv_imported', collection_id: id, user_id: user.id, data: {groups: groups_count, sites: sites_count}
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
    ["Site ID", "Type", "Name", "Lat", "Lng", "Parent ID", "Mode"]
  end
end
