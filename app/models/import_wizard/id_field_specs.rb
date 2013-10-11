class ImportWizard::IdFieldSpecs < ImportWizard::BaseFieldSpecs
  def initialize(collection, column_spec)
    @column_spec = column_spec
    if (pivot_id = column_spec[:id_matching_column]) && pivot_id != "resmap-id"
      @pivot_field = collection.identifier_fields.find pivot_id
      @mapping_for_pivot = @pivot_field.existing_values
    end
  end

  def column_spec_index
    @column_spec[:index]
  end

  def find_or_create_site(collection, row_value)
    if ((pivot_id = @column_spec[:id_matching_column]) && pivot_id != "resmap-id")
      # Pivot is an identifier field
      mapping_for_row = @mapping_for_pivot[row_value]
      if mapping_for_row
        # If the value exists in the collection, this is un update
        collection.sites.find_by_id(mapping_for_row["id"])
      else
        # If it doesn't a new site with this identifier value should be created
        collection.sites.new properties: {@pivot_field.es_code => row_value}, from_import_wizard: true
      end
    else
      # Pivot is resmap-id
      if row_value.empty?
        collection.sites.new properties: {}, from_import_wizard: true
      else
        collection.sites.find_by_id row_value
      end
    end
  end

end
