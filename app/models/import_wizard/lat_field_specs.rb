class ImportWizard::LatFieldSpecs < ImportWizard::BaseFieldSpecs
  def process(row, site, value)
    site.lat = value
  end
end
