class ImportWizard::ImportSpecs
  def initialize(columns_spec_array, collection)
    @collection = collection
    @existing_fields = collection.fields.each(&:cache_for_read).index_by &:id

    @data = columns_spec_array.map! &:with_indifferent_access
    relate_codes_and_labels_for_select_fields
  end

  def self.initial_guess(rows, collection, user)
    fields = collection.fields.index_by &:code
    columns_spec_array = []
    admin = user.admins? collection

    rows[0].each_with_index do |header, i|
      column_spec = {}
      column_spec[:header] = header ? header.strip : ''

      guess_column_usage(column_spec, fields, rows, i, admin, columns_spec_array)

      columns_spec_array << column_spec
    end

    columns_spec_array
  end

  def new_fields
    @new_fields
  end

  def validate_new_columns_do_not_exist_in_collection
    collection_fields = @collection.fields.all(:include => :layer)
    @data.each do |col_spec|
      if col_spec[:use_as] == 'new_field'
        # Validate code
        found = collection_fields.detect{|f| f.code == col_spec[:code]}
        if found
          raise "Can't save field from column #{col_spec[:header]}: A field with code '#{col_spec[:code]}' already exists in the layer named #{found.layer.name}"
        end
        # Validate name
        found = collection_fields.detect{|f| f.name == col_spec[:label]}
        if found
          raise "Can't save field from column #{col_spec[:header]}: A field with label '#{col_spec[:label]}' already exists in the layer named #{found.layer.name}"
        end
      end
    end
  end

  def annotate_index(header, index)
    spec = @data.find{|x| x[:header].strip == header}
    spec[:index] = index if spec
  end

  def create_id_column(collection)
    id_spec = @data.find{|x| x[:use_as].to_s == 'id'}
    if id_spec
      ImportWizard::IdFieldSpecs.new(collection, id_spec)
    end
  end

  def name_column
    @data.find{|x| x[:use_as].to_s == 'name'}
  end

  def create_import_wizard_layer(user)
    # Prepare the new layer
    layer = Layer.new name: 'Import wizard', ord: @collection.next_layer_ord
    layer.user = user
    layer.collection = @collection

    # Prepare the fields: we index by code, so later we can reference them faster
    @new_fields = {}

    # Fill the fields with the column specs.
    # We completely ignore the ones with selectKind equal to 'label', as processing those with
    # 'code' and 'both' is enough
    spec_i = 1
    @data.each do |spec|
      if spec[:use_as] == 'new_field'
        if spec[:selectKind] != 'label'
          # Set field to code if there's no label defined
          new_field_name = spec[:label].present? ? spec[:label] : spec[:code]

          field = layer.fields.new code: spec[:code], name: new_field_name, kind: spec[:kind], ord: spec_i, config: spec[:config]
          field.layer = layer

          # Special optimization for identifier fields, so we don't read ids from the
          # database all the time. This can't be enabled for 'select_one' or other fields
          # because their options might get built during the import wizard phase.
          if field.kind == 'identifier'
            field.cache_for_read
          end

          @new_fields[spec[:code]] = field

          spec_i += 1
        end
      end
    end

    # No need to create a layer if there are no new fields
    return nil unless spec_i > 1

    layer.save!
    layer
  end

  def each_column
    @data.each do |column|
      case column[:use_as]
      when 'new_field'
        yield ImportWizard::NewFieldSpecs.new(@new_fields, column)
      when 'existing_field'
        yield ImportWizard::ExistingFieldSpecs.new(@existing_fields, column)
      when 'name'
        yield ImportWizard::NameFieldSpecs.new(column)
      when 'lat'
        yield ImportWizard::LatFieldSpecs.new(column)
      when 'lng'
        yield ImportWizard::LngFieldSpecs.new(column)
      end
    end
  end

  private

  def relate_codes_and_labels_for_select_fields
    # Relate code and label select kinds for 'select one' and 'select many'
    @data.each do |spec|
      if spec[:use_as] == 'new_field' && (spec[:kind] == 'select_one' || spec[:kind] == 'select_many') && spec[:selectKind] == 'code'
          spec[:related] = @data.find{|x| x[:code] == spec[:code] && x[:selectKind] == 'label'}
      end
    end
  end

  def self.guess_column_usage(column, fields, rows, i, admin, spec_object_so_far)
    if column[:header] =~ /^resmap-id$/i
      column[:use_as] = :id
      column[:kind] = :id
      column[:id_matching_column] = "resmap-id"
      return
    end

    if (field = fields[column[:header]])
      if field.identifier? && !spec_object_so_far.any?{|spec| spec[:use_as] == :id}
        column[:use_as] = :id
        column[:id_matching_column] = field.id
      else
        column[:code] = column[:header].downcase.gsub(/\s+/, '') rescue ''
        column[:label] = column[:header].titleize rescue ''

        column[:use_as] = :existing_field
        column[:field_id] = field.id
        column[:layer_id] = field.layer_id
        column[:kind] = field.kind.to_sym
      end
      return
    end

    if column[:header] =~ /^name$/i
      column[:use_as] = :name
      column[:kind] = :name
      return
    end

    if column[:header] =~ /^\s*lat/i
      column[:use_as] = :lat
      column[:kind] = :location
      return
    end

    if column[:header] =~ /^\s*(lon|lng)/i
      column[:use_as] = :lng
      column[:kind] = :location
      return
    end

    if column[:header] =~ /last updated/i
      column[:use_as] = :ignore
      column[:kind] = :ignore
      return
    end

    if not admin
      column[:use_as] = :ignore
      return
    end

    found = false

    column[:code] = column[:header].downcase.gsub(/\s+/, '') rescue ''
    column[:label] = column[:header].titleize rescue ''

    rows[1 .. -1].each do |row|
      next if row[i].blank?

      found = true

      if row[i].start_with?('0')
        column[:use_as] = :new_field
        column[:kind] = :text

        return
      end

      begin
        Float(row[i])
      rescue
        column[:use_as] = :new_field
        column[:kind] = :text
        return
      end
    end

    if found
      column[:use_as] = :new_field
      column[:kind] = :numeric
    else
      column[:use_as] = :ignore
    end
  end
end
