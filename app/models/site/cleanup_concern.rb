module Site::CleanupConcern
  extend ActiveSupport::Concern

  included do
  	before_validation :remove_blank_properties, :if => :properties
  end

  def remove_blank_properties
    # False values are not rejected for the case of yes_no fields with value false, witch may be different for the ones without value.
    self.properties.reject! { |k, v| v!= false && v.blank? }
  end
end
