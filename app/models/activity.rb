class Activity < ActiveRecord::Base
  ItemTypesAndActions = {
    'collection' => %w(created imported csv_imported),
    'layer' => %w(created changed deleted),
    'site' => %w(created changed deleted)
  }
  Kinds = Activity::ItemTypesAndActions.map { |item_type, actions| actions.map { |action| "#{item_type},#{action}" } }.flatten

  belongs_to :collection
  belongs_to :user
  belongs_to :layer
  belongs_to :field
  belongs_to :site

  serialize :data

  validates_inclusion_of :item_type, :in => ItemTypesAndActions.keys

  def description
    case [item_type, action]
    when ['collection', 'created']
      "Collection '#{data['name']}' was created"
    when 'collection_imported'
      "Import wizard: #{sites_were_imported_text}"
    when ['collection', 'csv_imported']
      "Import CSV: #{sites_were_imported_text}"
    when ['layer', 'created']
      fields_str = data['fields'].map { |f| "#{f['name']} (#{f['code']})" }.join ', '
      str = "Layer '#{data['name']}' was created with fields: #{fields_str}"
    when ['layer', 'changed']
      layer_changed_text
    when ['layer', 'deleted']
      str = "Layer '#{data['name']}' was deleted"
    when ['site', 'created']
      "Site '#{data['name']}' was created"
    when ['site', 'changed']
      site_changed_text
    when ['site', 'deleted']
      "Site '#{data['name']}' was deleted"
    end
  end

  def item_id
    case item_type
    when 'collection'
      collection_id
    when 'layer'
      layer_id
    when 'site'
      site_id
    end
  end

  private

  def sites_were_imported_text
    sites_created_text = "#{data['sites']} site#{data['sites'] == 1 ? '' : 's'}"
    "#{sites_created_text} were imported"
  end

  def site_changed_text
    only_name_changed, changes = site_changes_text
    if only_name_changed
      "Site '#{data['name']}' was renamed to '#{data['changes']['name'][1]}'"
    else
      "Site '#{data['name']}' changed: #{changes}"
    end
  end

  def site_changes_text
    fields = collection.fields.index_by(&:es_code)

    text_changes = []
    only_name_changed = false

    if (change = data['changes']['name'])
      text_changes << "name changed from '#{change[0]}' to '#{change[1]}'"
      only_name_changed = true
    end

    if (lat_change = data['changes']['lat']) && (lng_change = data['changes']['lng'])
      text_changes << "location changed from #{format_location data['changes'], :from} to #{format_location data['changes'], :to}"
      only_name_changed = false
    end

    if data['changes']['properties']
      properties = data['changes']['properties']
      properties[0].each do |key, old_value|
        new_value = properties[1][key]
        if new_value != old_value
          field = fields[key]
          code = field.try(:code)
          text_changes << "'#{code}' changed from #{format_value field, old_value} to #{format_value field, new_value}"
        end
      end

      properties[1].each do |key, new_value|
        if !properties[0].has_key? key
          field = fields[key]
          code = field.try(:code)
          text_changes << "'#{code}' changed from (nothing) to #{new_value.nil? ? '(nothing)' : format_value(field, new_value)}"
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
            text_changes << "#{old_value field['kind']} field '#{old_value field['name']}' (#{old_value field['code']}) options changed from #{format_options old_options} to #{format_options new_options}"
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

  def format_value(field, value)
    if field && field.select_one?
      format_option field, value
    elsif field && field.select_many? && value.is_a?(Array)
      value.map { |v| format_option field, v }
    else
      value.is_a?(String) ? "'#{value}'" : value
    end
  end

  def format_option(field, value)
    option = field.config['options'].find { |o| o['id'] == value }
    option ? "#{option['label']} (#{option['code']})" : value
  end

  def format_options(options)
    (options || []).map { |option| "#{option['label']} (#{option['code']})" }
  end

  def format_location(changes, dir)
    idx = dir == :from ? 0 : 1
    lat = changes['lat'][idx]
    lng = changes['lng'][idx]
    if lat
      "(#{((lat) * 1e6).round / 1e6.to_f}, #{((lng) * 1e6).round / 1e6.to_f})"
    else
      '(nothing)'
    end
  end
end
