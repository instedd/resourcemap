class ImportWizard::NewFieldSpecs < ImportWizard::BaseFieldSpecs
  def initialize(new_fields, column_spec)
    super(column_spec)
    @new_fields = new_fields
  end

  def process(row, site)
    value = row[@column_spec[:index]]

    # New hierarchy fields cannot be created via import wizard
    raise "Hierarchy fields can only be created via web in the Layers page" if @column_spec[:kind] == 'hierarchy'

    # For select one and many we need to collect the fields options
    if @column_spec[:kind] == 'select_one'  || @column_spec[:kind] == 'select_many'
      # For select_one fields each value will be only one option
      # and for select_many fields we may create more than one option per value
      options_to_be_created = if @column_spec[:kind] == 'select_many'
        value.split(',').map{|v| v.strip}
      else
        [value]
      end

      options_to_be_created.each do |option|
        field = @new_fields[@column_spec[:code]]
        field.config ||= {'options' => [], 'next_id' => 1}

        code = nil
        label = nil

        # Compute code and label based on the selectKind
        case @column_spec[:selectKind]
        when 'code'
          next unless @column_spec[:related]

          code = option

          label = row[@column_spec[:related][:index]]
        when 'label'
          # Processing just the code is enough
          return
        when 'both'
          code = option
          label = option
        end

        # Add to options, if not already present
        if code.present? && !label.nil?
          existing = field.config['options'].find{|x| x['code'] == code}
          if !existing
            field.config['options'] << {'id' => field.config['next_id'], 'code' => code, 'label' => label}
            field.config['next_id'] += 1
          end
        end
      end
    end

    field = @new_fields[@column_spec[:code]]
    site.properties_will_change!

    site.properties[field.es_code] = field.apply_format_and_validate value, true, field.layer.collection
  end
end
