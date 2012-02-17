require 'csv'

module Collection::CsvConcern
  extend ActiveSupport::Concern

  def export_csv
    CSV.generate do |csv|
      csv << ["ID", "Name", "Lat", "Lng", "Parent ID", "Mode"]
      sites.each do |site|
        csv << [site.id, site.name, site.lat, site.lng, site.parent_id, site.group ? site.location_mode : nil]
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

        site = sites.new :name => row[1].strip
        site.lat = row[2].strip if row[2].present?
        site.lng = row[3].strip if row[3].present?
        site.location_mode = row[5].strip if row[5].present?
        hash[row[0].strip] = [site, row[4]]
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
end
