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

  def import_csv!(string_or_io)
    Collection.transaction do
      csv = CSV.new string_or_io, :return_headers => false

      # Create a hash of id => [site, parent]
      hash = Hash.new
      csv.each do |row|
        next unless row[0].present?

        site = sites.new :name => row[2].strip
        site.group = row[1].try(:strip).try(:downcase) == 'group'
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
    end
  end

  private

  def csv_header
    ["ID", "Type", "Name", "Lat", "Lng", "Parent ID", "Mode"]
  end
end
