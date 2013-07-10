class ImportWizard::LatFieldSpecs < ImportWizard::BaseFieldSpecs
  def process(row, site)
    site.lat = row[@column_spec[:index]]
  end
end
