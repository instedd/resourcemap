class Site < ActiveRecord::Base
  include Activity::AwareConcern
  include Site::ActivityConcern
  include Site::GeomConcern
  include Site::TireConcern

  belongs_to :collection

  serialize :properties, Hash

  before_save :remove_nil_properties, :if => :properties
  def remove_nil_properties
    self.properties.reject! { |k, v| v.nil? }
  end
end
