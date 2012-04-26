class Activity < ActiveRecord::Base
  belongs_to :collection
  belongs_to :user
  belongs_to :layer
  belongs_to :field
  belongs_to :site

  serialize :data

  def description
    case kind
    when 'collection_created'
      "Collection '#{data[:name]}' was created"
    when 'collection_imported'
      "Import wizard: #{groups_and_sites_were_imported_text}"
    when 'collection_csv_imported'
      "Import CSV: #{groups_and_sites_were_imported_text}"
    when 'layer_created'
      fields_str = data[:fields].map { |f| "#{f[:name]} (#{f[:code]})" }.join ', '
      str = "Layer '#{data[:name]}' was created with fields: #{fields_str}"
    when 'site_created'
      "Site '#{data[:name]}' was created"
    when 'group_created'
      "Group '#{data[:name]}' was created"
    when 'site_changed'
      "Site '#{data[:name]}' changed: #{site_changes_text}"
    when 'group_changed'
      "Group '#{data[:name]}' changed: #{site_changes_text}"
    when 'site_deleted'
      "Site '#{data[:name]}' was deleted"
    when 'group_deleted'
      "Group '#{data[:name]}' was deleted"
    end
  end

  private

  def groups_and_sites_were_imported_text
    groups_created_text = "#{data[:groups]} group#{data[:groups] == 1 ? '' : 's'}"
    sites_created_text = "#{data[:sites]} site#{data[:sites] == 1 ? '' : 's'}"
    "#{groups_created_text} and #{sites_created_text} were imported"
  end

  def site_changes_text
    text_changes = []

    if (change = data[:changes]['name'])
      text_changes << "name changed from '#{change[0]}' to '#{change[1]}'"
    end

    if (lat_change = data[:changes]['lat']) && (lng_change = data[:changes]['lng'])
      text_changes << "location changed from (#{format_location lat_change[0]}, #{format_location lng_change[0]}) to (#{format_location lat_change[1]}, #{format_location lng_change[1]})"
    end

    if data[:changes]['properties']
      properties = data[:changes]['properties']
      properties[0].each do |key, old_value|
        new_value = properties[1][key]
        if new_value != old_value
          text_changes << "'#{key}' changed from #{format_value old_value} to #{format_value new_value}"
        end
      end

      properties[1].each do |key, new_value|
        if !properties[0].has_key? key
          text_changes << "'#{key}' changed from (nothing) to #{format_value new_value}"
        end
      end
    end

    text_changes.join ', '
  end

  def format_value(value)
    value.is_a?(String) ? "'#{value}'" : value
  end

  def format_location(value)
    (value * 1e6).round / 1e6.to_f
  end
end
