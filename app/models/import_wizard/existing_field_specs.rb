class ImportWizard::ExistingFieldSpecs < ImportWizard::BaseFieldSpecs
  def initialize(existing_fields, column_spec)
    super(column_spec)
    @existing_fields = existing_fields
  end

  def process(row, site)
    value = row[@column_spec[:index]]
    existing_field = @existing_fields[@column_spec[:field_id].to_i]

    if existing_field
      case existing_field.kind
        when 'select_one'
          add_new_option_to_field_if_needed existing_field, value

          site.properties_will_change!
          site.properties[existing_field.es_code] = existing_field.apply_format_and_validate value, true, site.collection
        when 'select_many'
          site.properties[existing_field.es_code] = []

          value.split(',').each do |v|
            option = v.strip

            add_new_option_to_field_if_needed existing_field, option

            option = existing_field.apply_format_and_validate(option, true, site.collection).first

            site.properties_will_change!
            site.properties[existing_field.es_code] << option
          end
        else
          site.properties_will_change!
          site.properties[existing_field.es_code] = existing_field.apply_format_and_validate value, true, site.collection
      end
    end
  end

  private

  # TODO: move this to the field
  def add_new_option_to_field_if_needed(field, value)
    # Add option to field options if it doesnt exist
    existing_option = field.config['options'].find { |x| x['code'] == value }

    if !existing_option
      field.config['options'] << { 'id' => field.config['next_id'], 'code' => value, 'label' => value }
      field.config['next_id'] += 1

      # Save the field so the new option is available from now on
      field.save!
    end
  end
end
