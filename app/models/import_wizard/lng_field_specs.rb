class ImportWizard::LngFieldSpecs < ImportWizard::BaseFieldSpecs
  def process(row, site)
    site.lng = row[@column_spec[:index]]
  end
end
