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
      "Collection '#{data['name']}' was created"
    when 'collection_imported'
      "Import wizard: #{groups_and_sites_were_imported_text}"
    when 'collection_csv_imported'
      "Import CSV: #{groups_and_sites_were_imported_text}"
    when 'layer_created'
      fields_str = data['fields'].map { |f| "#{f['name']} (#{f['code']})" }.join ', '
      str = "Layer '#{data['name']}' was created with fields: #{fields_str}"
    when 'layer_changed'
      layer_changed_text
    when 'layer_deleted'
      str = "Layer '#{data['name']}' was deleted"
    when 'site_created'
      "Site '#{data['name']}' was created"
    when 'group_created'
      "Group '#{data['name']}' was created"
    when 'site_changed'
      site_or_group_changed_text 'Site'
    when 'group_changed'
      site_or_group_changed_text 'Group'
    when 'site_deleted'
      "Site '#{data['name']}' was deleted"
    when 'group_deleted'
      "Group '#{data['name']}' was deleted"
    end
  end

  private

  def groups_and_sites_were_imported_text
    groups_created_text = "#{data['groups']} group#{data['groups'] == 1 ? '' : 's'}"
    sites_created_text = "#{data['sites']} site#{data['sites'] == 1 ? '' : 's'}"
    "#{groups_created_text} and #{sites_created_text} were imported"
  end

  def site_or_group_changed_text(model_name)
    only_name_changed, changes = site_changes_text
    if only_name_changed
      "#{model_name} '#{data['name']}' was renamed to '#{data['changes']['name'][1]}'"
    else
      "#{model_name} '#{data['name']}' changed: #{changes}"
    end
  end

  def site_changes_text
    text_changes = []
    only_name_changed = false

    if (change = data['changes']['name'])
      text_changes << "name changed from '#{change[0]}' to '#{change[1]}'"
      only_name_changed = true
    end

    if (lat_change = data['changes']['lat']) && (lng_change = data['changes']['lng'])
      text_changes << "location changed from (#{format_location lat_change[0]}, #{format_location lng_change[0]}) to (#{format_location lat_change[1]}, #{format_location lng_change[1]})"
      only_name_changed = false
    end

    if data['changes']['properties']
      properties = data['changes']['properties']
      properties[0].each do |key, old_value|
        new_value = properties[1][key]
        if new_value != old_value
          text_changes << "'#{key}' changed from #{format_value old_value} to #{format_value new_value}"
        end
      end

      properties[1].each do |key, new_value|
        if !properties[0].has_key? key
          text_changes << "'#{key}' changed from (nothing) to #{new_value.nil? ? '(nothing)' : format_value(new_value)}"
        end
      end

      only_name_changed = false
    end

    [only_name_changed, text_changes.join(', ')]
  end

  def layer_changed_text
    only_name_changed, changes = layer_changes_text
    if only_name_changed
      "Layer '#{data['name']}' was renamed to '#{data['changes']['name'][1]}'"
    else
      "Layer '#{data['name']}' changed: #{changes}"
    end
  end

  def layer_changes_text
    text_changes = []
    only_name_changed = false

    if (change = data['changes']['name'])
      text_changes << "name changed from '#{change[0]}' to '#{change[1]}'"
      only_name_changed = true
    end

    if data['changes']['added']
      data['changes']['added'].each do |field|
        text_changes << "#{field['kind']} field '#{field['name']}' (#{field['code']}) was added"
      end
      only_name_changed = false
    end

    if data['changes']['changed']
      data['changes']['changed'].each do |field|
        ['name', 'code', 'kind'].each do |key|
          if field[key].is_a? Array
            text_changes << "#{old_value field['kind']} field '#{old_value field['name']}' (#{old_value field['code']}) #{key} changed to '#{field[key][1]}'"
          end
        end

        if field['config'].is_a?(Array)
          old_options = (field['config'][0] || {})['options']
          new_options = (field['config'][1] || {})['options']
          if old_options != new_options
            text_changes << "#{old_value field['kind']} field '#{old_value field['name']}' (#{old_value field['code']}) options changed from #{old_options} to #{new_options}"
          end
        end
      end
      only_name_changed = false
    end

    if data['changes']['deleted']
      data['changes']['deleted'].each do |field|
        text_changes << "#{field['kind']} field '#{field['name']}' (#{field['code']}) was deleted"
      end
      only_name_changed = false
    end

    [only_name_changed, text_changes.join(', ')]
  end

  def old_value(value)
    value.is_a?(Array) ? value[0] : value
  end

  def format_value(value)
    value.is_a?(String) ? "'#{value}'" : value
  end

  def format_location(value)
    ((value || 0) * 1e6).round / 1e6.to_f
  end
end
