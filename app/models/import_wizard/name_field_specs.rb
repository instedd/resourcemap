class ImportWizard::NameFieldSpecs < ImportWizard::BaseFieldSpecs
  def process(row, site, value)
    site.name = value
  end
end
