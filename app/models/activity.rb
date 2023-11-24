class Activity < ApplicationRecord
  ItemTypesAndActions = {
    'collection' => %w(created imported),
    'layer' => %w(created changed deleted),
    'site' => %w(created changed deleted),
    'membership' => %w(created deleted),
    'layer_membership' => %w(changed),
    'name_permission' => %w(changed),
    'location_permission' => %w(changed),
    'anonymous_name_location_permission' => %w(changed),
    'anonymous_layer_permission' => %w(changed),
    'admin_permission' => %w(changed),
  }
  Kinds = Activity::ItemTypesAndActions.map { |item_type, actions| actions.map { |action| "#{item_type},#{action}" } }.flatten.freeze

  belongs_to :collection
  belongs_to :user
  belongs_to :layer
  belongs_to :field
  belongs_to :site

  serialize :data, MarshalZipSerializable

  validates_inclusion_of :item_type, :in => ItemTypesAndActions.keys

  def description
    case [item_type, action]
    when ['collection', 'created']
      _("Collection '%{name}' was created") % {name: "#{data['name']}"}
    when ['collection', 'imported']
      _("New CSV imported into collection '%{name}'") % {name: "#{data['name']}"}
    when ['layer', 'created']
      fields_str = data['fields'].map { |f| "#{f['name']} (#{f['code']})" }.join ', '
      str = _("Layer %{layer} was created with fields: %{fields}") % {layer: "'#{data['name']}'", fields: "#{fields_str}"}
    when ['layer', 'changed']
      layer_changed_text
    when ['layer', 'deleted']
      str = _("Layer %{layer} was deleted") % {layer: "'#{data['name']}'" }
    when ['site', 'created']
      _("Site %{site} was created") % {site: "'#{data['name']}'"}
    when ['site', 'changed']
      site_changed_text
    when ['site', 'deleted']
      _("Site %{site} was deleted") % {site: "'#{data['name']}'"}
    when ['membership', 'created']
      _("Member %{user} was added") % {user: "#{data['user']}"}
    when ['membership', 'deleted']
      _("Member %{user} was removed") % {user: "#{data['user']}"}
    when ['layer_membership', 'changed']
      (data['previous_permission'] && data['new_permission'] ?
        _("Permission changed from %{previous_permission} to %{new_permission} in layer %{layer} for %{user}") :
        _("Permission changed in layer %{layer} for %{user}")
      ) % {
        previous_permission: data['previous_permission'],
        new_permission: data['new_permission'],
        layer: "'#{data['name']}'",
        user: data['user']
      }
    when ['name_permission', 'changed']
      (data.nil? || data['changes'].nil? ?
        _("Permission changed in name layer for %{user}") :
        _("Permission changed from %{previous_permission} to %{new_permission} in name layer for %{user}")
      ) % {previous_permission: (data['changes'][0] rescue nil), new_permission: (data['changes'][1] rescue nil), user: data['user']}
    when['location_permission', 'changed']
      (data.nil? || data['changes'].nil? ?
        _("Permission changed in location layer for %{user}") :
        _("Permission changed from %{previous_permission} to %{new_permission} in location layer for #{data['user']}")
      ) % {previous_permission: (data['changes'][0] rescue nil), new_permission: (data['changes'][1] rescue nil), user: data['user']}
    when['anonymous_name_location_permission', 'changed']
      (data.nil? || data['changes'].nil? ?
        _("Permission changed in %{layer} layer for anonymous users") :
        _("Permission changed from %{previous_permission} to %{new_permission} in %{layer} layer for anonymous users")
      ) % {previous_permission: (data['changes'][0] rescue nil), new_permission: (data['changes'][1] rescue nil), layer: data['built_in_layer']}
    when['anonymous_layer_permission', 'changed']
      (data.nil? || data['changes'].nil? ?
        _("Permission changed in layer %{layer} for anonymous users") :
        _("Permission changed from %{previous_permission} to %{new_permission} in layer %{layer} for anonymous users")
      ) % {previous_permission: (data['changes'][0] rescue nil), new_permission: (data['changes'][1] rescue nil), layer: "'#{data['name']}'"}
    when['admin_permission','changed']
      admin_permission_changed data
    end rescue _("There was an error processing this activity")
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
    sites_created_text = "#{data['sites']} #{data['sites'] == 1 ? _("site") : _("sites")}"
    _("%{sites} were imported") % {sites: sites_created_text}
  end

  def site_changed_text
    only_name_changed, changes = site_changes_text
    if only_name_changed
      _("Site '%{old_name}' was renamed to '%{new_name}'") % {old_name: data['name'], new_name: data['changes']['name'][1]}
    else
      _("Site '%{site_name}' changed: %{changes}") % {site_name: data['name'], changes: changes}
    end
  end

  def site_changes_text
    fields = collection.fields.index_by(&:es_code)

    text_changes = []
    only_name_changed = false

    if (change = data['changes']['name'])
      text_changes << _("name changed from '%{old_name}' to '%{new_name}'") % {old_name: change[0], new_name: change[1]}
      only_name_changed = true
    end

    if (lat_change = data['changes']['lat']) && (lng_change = data['changes']['lng'])
      text_changes << _("location changed from %{old_location} to %{new_location}") % {old_location: format_location(data['changes'], :from), new_location: format_location(data['changes'], :to)}
      only_name_changed = false
    end

    if data['changes']['properties']
      properties = data['changes']['properties']
      properties[0].each do |key, old_value|
        new_value = properties[1][key]
        if new_value != old_value
          field = fields[key]
          code = field.try(:code)
          text_changes << _("'%{code}' changed from %{old_value} to %{new_value}") % {code: code, old_value: format_value(field, old_value), new_value: new_value.nil? ? '(nothing)' : format_value(field, new_value)}
        end
      end

      properties[1].each do |key, new_value|
        if !properties[0].has_key? key
          field = fields[key]
          code = field.try(:code)
          text_changes << _("'%{code}' changed from (nothing) to %{new_value}") % {code: code, new_value: new_value.nil? ? '(nothing)' : format_value(field, new_value)}
        end
      end

      only_name_changed = false
    end

    [only_name_changed, text_changes.join(', ')]
  end

  def layer_changed_text
    only_name_changed, changes = layer_changes_text
    if only_name_changed
      _("Layer %{layer} was renamed to %{changes}") % {layer: "'#{data['name']}'", changes: "'#{data['changes']['name'][1]}'"}
    else
      _("Layer %{layer} changed: %{changes}") % {layer: "'#{data['name']}'", changes: "#{changes}"}
    end
  end

  def admin_permission_changed(data)
    if (data['value'])
      _("%{user} became an administrator") % {user: data['user'] }
    else
      _("%{user} removed from administrators group") % {user: data['user'] }
    end
  end

  def layer_changes_text
    text_changes = []
    only_name_changed = false

    if (change = data['changes']['name'])
      text_changes << _("name changed from %{first_change} to %{second_change}") % {first_change: "#{change[0]}", second_change: "#{change[1]}"}
      only_name_changed = true
    end

    if data['changes']['added']
      data['changes']['added'].each do |field|
        text_changes << _("%{kind} field %{name} %{code} was added") % {kind: "#{field['kind']}", name: "'#{field['name']}'", code: "(#{field['code']})"}
      end
      only_name_changed = false
    end

    if data['changes']['changed']
      data['changes']['changed'].each do |field|
        ['name', 'code', 'kind'].each do |key|
          if field[key].is_a? Array
            text_changes << _("%{kind} field '%{name}' %{code} %{key} changed to %{field_key}") % {kind: "#{old_value field['kind']}", name: "#{old_value field['name']}", code: "(#{old_value field['code']})", key: "#{key}", field_key: "'#{field[key][1]}'"}
          end
        end

        if field['config'].is_a?(Array)
          old_options = (field['config'][0] || {})['options']
          new_options = (field['config'][1] || {})['options']
          if old_options != new_options
            text_changes << _("%{kind} field %{name} %{code} options changed from %{old_options} to %{new_options}") % {kind: "#{old_value field['kind']}", name: "'#{old_value field['name']}'", code: "(#{old_value field['code']})", old_options: "#{format_options old_options}", new_options: "#{format_options new_options}"}
          end
        end
      end
      only_name_changed = false
    end

    if data['changes']['deleted']
      data['changes']['deleted'].each do |field|
        text_changes << _("%{kind} field %{name} %{code} was deleted") % {kind: "#{field['kind']}", name: "'#{field['name']}'", code: "(#{field['code']})"}
      end
      only_name_changed = false
    end

    [only_name_changed, text_changes.join(', ')]
  end

  def old_value(value)
    value.is_a?(Array) ? value[0] : value
  end

  def format_value(field, value)
    if field && field.yes_no?
      value == _('true') || value == '1' ? _('yes') : _('no')
    elsif field && field.select_one?
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
      _('(nothing)')
    end
  end

end
