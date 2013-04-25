module Site::CleanupConcern
  extend ActiveSupport::Concern

  included do
    before_save :remove_nil_properties, :if => :properties
  end

  def remove_nil_properties
    self.properties.reject! { |k, v| v.nil? }
  end
end
