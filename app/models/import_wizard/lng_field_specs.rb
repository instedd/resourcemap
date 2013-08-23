class ImportWizard::LngFieldSpecs < ImportWizard::BaseFieldSpecs
  def process(row, site, value)
    site.lng = value
  end
end
