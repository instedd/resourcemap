# Load all Field classes to make associations like "text_fields" and "numeric_fields" work
ActiveSupport::Reloader.to_prepare do
  Dir[File.expand_path(Rails.root.join("app/models/field/*.rb"))].each do |file|
    require_dependency file
  end
end
