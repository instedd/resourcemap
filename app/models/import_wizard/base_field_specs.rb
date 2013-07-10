class ImportWizard::BaseFieldSpecs
  def initialize(column_spec)
    @column_spec = column_spec
  end

  def index
    @column_spec[:index]
  end
end
