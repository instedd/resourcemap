class ImportWizard::ImportSpecs
  def initialize(columns_spec_array, collection)
    @collection = collection
    @existing_fields = collection.fields.index_by &:id

    @data = columns_spec_array.map! &:with_indifferent_access
    relate_codes_and_labels_for_select_fields
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

  def id_column
    @data.find{|x| x[:use_as] == 'id'}
  end

  def name_column
    @data.find{|x| x[:use_as] == 'name'}
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

          @new_fields[spec[:code]] = layer.fields.new code: spec[:code], name: new_field_name, kind: spec[:kind], ord: spec_i
          @new_fields[spec[:code]].layer = layer
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
end
