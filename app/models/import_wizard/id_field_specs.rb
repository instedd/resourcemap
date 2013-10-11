class ImportWizard::IdFieldSpecs < ImportWizard::BaseFieldSpecs
  def initialize(collection, column_spec)
    @column_spec = column_spec
    if (pivot_id = column_spec[:id_matching_column]) && pivot_id != "resmap-id"
      pivot_field = collection.identifier_fields.find pivot_id
      @mapping_for_pivot = pivot_field.existing_values
    end
  end

  def column_spec_index
    @column_spec[:index]
  end

  def site_id_for(row_value)
    if @mapping_for_pivot
      @mapping_for_pivot[row_value]["id"]
    else
      row_value
    end
  end

end
