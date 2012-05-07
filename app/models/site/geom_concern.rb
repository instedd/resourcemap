module Site::GeomConcern
  extend ActiveSupport::Concern

  included do
    after_save  :compute_collection_center!, :if => lambda { new_record? || lat_changed? || lng_changed? }
    after_destroy :compute_collection_center!
  end

  def compute_collection_center!
    collection.compute_center!
  end
end
