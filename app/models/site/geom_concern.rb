module Site::GeomConcern
  extend ActiveSupport::Concern

  included do
    after_save  :compute_collection_bounding_box!, :if => lambda { (new_record? || lat_changed? || lng_changed?) && !from_import_wizard }
    after_destroy :compute_collection_bounding_box!
  end

  def compute_collection_bounding_box!
    collection.compute_bounding_box!
  end
end
