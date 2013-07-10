class ImportWizard::NameFieldSpecs < ImportWizard::BaseFieldSpecs
  def process(row, site)
    site.name = row[@column_spec[:index]]
  end
end
