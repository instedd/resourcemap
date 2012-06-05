module Site::CleanupConcern
  extend ActiveSupport::Concern

  included do
    before_save :strongly_type_properties
    before_save :remove_nil_properties, :if => :properties
  end

  def strongly_type_properties
    fields = collection.fields.index_by(&:es_code)
    self.properties.keys.each do |key|
      field = fields[key]
      self.properties[key] = field.strongly_type(properties[key]) if field
    end
  end

  def remove_nil_properties
    self.properties.reject! { |k, v| v.nil? }
  end
end
